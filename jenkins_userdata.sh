#!/bin/bash
# Jenkins setup and configuration script for AWS EC2

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install necessary packages
sudo apt install -y openjdk-17-jdk git python3 python3-pip python3-venv unzip software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt install -y python3.7 python3.7-venv

# Add the Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update and install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Set up Jenkins user
sudo passwd jenkins << EOF
jenkins123
jenkins123
EOF

# Create a directory for the Jenkins workspace
sudo mkdir -p /var/lib/jenkins/workspace
sudo chown -R jenkins:jenkins /var/lib/jenkins/workspace

# Give jenkins user sudo access (needed for some operations)
echo "jenkins ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/jenkins

# Wait for Jenkins to be fully up
echo "Waiting for Jenkins to be fully up..."
sleep 30

# Get the admin password
ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
echo "Jenkins initial admin password: $ADMIN_PASSWORD"

# Create a log file to store the Jenkins admin password
echo "Jenkins initial admin password: $ADMIN_PASSWORD" | sudo tee /home/ubuntu/jenkins_password.txt

# Install Elastic Beanstalk CLI for jenkins user
sudo su - jenkins << EOF
mkdir -p ~/.local/bin
pip install --user awsebcli
echo 'export PATH=~/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
EOF

# Create Multibranch Pipeline job configuration
cat > job_config.xml << 'EOL'
<?xml version='1.1' encoding='UTF-8'?>
<org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject plugin="workflow-multibranch@2.26">
  <actions/>
  <description></description>
  <properties>
    <org.jenkinsci.plugins.pipeline.modeldefinition.config.FolderConfig plugin="pipeline-model-definition@1.9.3">
      <dockerLabel></dockerLabel>
      <registry plugin="docker-commons@1.19"/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.config.FolderConfig>
  </properties>
  <folderViews class="jenkins.branch.MultiBranchProjectViewHolder" plugin="branch-api@2.7.0">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </folderViews>
  <healthMetrics>
    <com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric plugin="cloudbees-folder@6.16">
      <nonRecursive>false</nonRecursive>
    </com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
  </healthMetrics>
  <icon class="jenkins.branch.MetadataActionFolderIcon" plugin="branch-api@2.7.0">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </icon>
  <orphanedItemStrategy class="com.cloudbees.hudson.plugins.folder.computed.DefaultOrphanedItemStrategy" plugin="cloudbees-folder@6.16">
    <pruneDeadBranches>true</pruneDeadBranches>
    <daysToKeep>-1</daysToKeep>
    <numToKeep>-1</numToKeep>
  </orphanedItemStrategy>
  <triggers>
    <com.cloudbees.hudson.plugins.folder.computed.PeriodicFolderTrigger plugin="cloudbees-folder@6.16">
      <spec>H/5 * * * *</spec>
      <interval>300000</interval>
    </com.cloudbees.hudson.plugins.folder.computed.PeriodicFolderTrigger>
  </triggers>
  <disabled>false</disabled>
  <sources class="jenkins.branch.MultiBranchProject$BranchSourceList" plugin="branch-api@2.7.0">
    <data>
      <jenkins.branch.BranchSource>
        <source class="jenkins.plugins.git.GitSCMSource" plugin="git@4.11.0">
          <id>1234567890</id>
          <remote>${github_repo_url}</remote>
          <credentialsId></credentialsId>
          <traits>
            <jenkins.plugins.git.traits.BranchDiscoveryTrait/>
          </traits>
        </source>
        <strategy class="jenkins.branch.DefaultBranchPropertyStrategy">
          <properties class="empty-list"/>
        </strategy>
      </jenkins.branch.BranchSource>
    </data>
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </sources>
  <factory class="org.jenkinsci.plugins.workflow.multibranch.WorkflowBranchProjectFactory">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
    <scriptPath>Jenkinsfile</scriptPath>
  </factory>
</org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject>
EOL

# Download and save the jenkinscli.jar for later use
sudo mkdir -p /home/ubuntu/jenkins_setup
cd /home/ubuntu/jenkins_setup
wget -q -O jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar
chmod +x jenkins-cli.jar

# Create a setup script for the admin user to run after first login
cat > /home/ubuntu/jenkins_setup/setup_jenkins.sh << 'EOL'
#!/bin/bash

# This script should be run after the first login to Jenkins

# Check if admin password is provided as argument
if [ -z "$1" ]; then
    echo "Usage: $0 <admin_password>"
    echo "Admin password can be found in /home/ubuntu/jenkins_password.txt"
    exit 1
fi

ADMIN_PASSWORD=$1
cd /home/ubuntu/jenkins_setup

# Install necessary plugins
echo "Installing necessary plugins..."
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD install-plugin workflow-aggregator git junit pipeline-stage-view blueocean docker-workflow pipeline-github-lib pipeline-rest-api ssh-agent -deploy

# Restart Jenkins
echo "Restarting Jenkins..."
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD safe-restart

# Wait for Jenkins to restart
echo "Waiting for Jenkins to restart..."
sleep 30

# Create the job
echo "Creating job 'eb-ecommerce'..."
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD create-job eb-ecommerce < /home/ubuntu/job_config.xml

echo "Jenkins configuration complete!"
echo "Your Multibranch Pipeline 'eb-ecommerce' has been created."
EOL

chmod +x /home/ubuntu/jenkins_setup/setup_jenkins.sh

# Create a readme file with instructions
cat > /home/ubuntu/README.txt << 'EOL'
Jenkins Server Setup Instructions
================================

1. Access Jenkins at http://YOUR_SERVER_IP:8080

2. For the initial setup, use the admin password found in:
   /home/ubuntu/jenkins_password.txt

3. Install the suggested plugins when prompted.

4. Create your admin user when prompted.

5. After completing the initial setup, run the following command to complete the configuration:
   /home/ubuntu/jenkins_setup/setup_jenkins.sh <admin_password>
   (Use the password you set for your admin user)

6. For the Jenkins user:
   - Username: jenkins
   - Password: jenkins123

7. Complete AWS CLI configuration:
   sudo su - jenkins
   aws configure
   (Enter your AWS access key, secret key, region (us-east-1), and output format (json))

8. To check if the Elastic Beanstalk CLI is installed correctly:
   eb --version

Important: Remember to change the default passwords for security purposes!
EOL

# Set proper permissions
sudo chown -R ubuntu:ubuntu /home/ubuntu/jenkins_setup
sudo chown ubuntu:ubuntu /home/ubuntu/README.txt
sudo chown ubuntu:ubuntu /home/ubuntu/job_config.xml

echo "EC2 instance setup complete! Jenkins is now installed."