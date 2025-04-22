#!/bin/bash
# Fully automated Jenkins setup script for CI/CD pipeline with AWS Elastic Beanstalk (silent version)

# Update system packages
sudo apt update -y
sudo apt upgrade -y

# Install required system packages
sudo apt install -y openjdk-17-jdk git python3 python3-pip python3-venv unzip software-properties-common expect

# Add and install Python 3.10
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt install -y python3.10 python3.10-venv

# Configure Jenkins repository and install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Configure AWS credentials for jenkins user
sudo mkdir -p /var/lib/jenkins/.aws
sudo tee /var/lib/jenkins/.aws/credentials > /dev/null << EOF
[default]
aws_access_key_id = ${aws_access_key}
aws_secret_access_key = ${aws_secret_key}
EOF

sudo tee /var/lib/jenkins/.aws/config > /dev/null << EOF
[default]
region = us-east-1
output = json
EOF

# Install EB CLI for jenkins user using official method
sudo -u jenkins bash -c "cd /tmp && git clone https://github.com/aws/aws-elastic-beanstalk-cli-setup.git"
sudo -u jenkins bash -c "cd /tmp && python3 aws-elastic-beanstalk-cli-setup/scripts/ebcli_installer.py"

# Add EB CLI to jenkins user path
EBCLI_PATH=$(sudo -u jenkins bash -c "find /var/lib/jenkins/.ebcli-virtual-env -name 'eb' -type f | head -n 1")
EBCLI_DIR=$(dirname "$EBCLI_PATH")
sudo -u jenkins bash -c "echo 'export PATH=$EBCLI_DIR:\$PATH' >> /var/lib/jenkins/.bashrc"
sudo -u jenkins bash -c "source /var/lib/jenkins/.bashrc"

# Set proper permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins/.aws
sudo chmod 600 /var/lib/jenkins/.aws/credentials
sudo chmod 644 /var/lib/jenkins/.aws/config

# Wait for Jenkins to be fully initialized
while ! sudo test -f /var/lib/jenkins/secrets/initialAdminPassword; do
    sleep 5
done

# Retrieve the initial admin password
ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Wait for Jenkins web interface
while ! curl -s http://localhost:8080/login > /dev/null; do
    sleep 5
done

# Download Jenkins CLI
cd /tmp
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Install required Jenkins plugins
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD install-plugin workflow-aggregator git junit pipeline-stage-view blueocean docker-workflow pipeline-github-lib pipeline-rest-api ssh-agent -deploy

# Wait for plugins to be installed
sleep 60

# Create Multibranch Pipeline job
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
  <disabled>false</disabled>
  <sources class="jenkins.branch.MultiBranchProject$BranchSourceList" plugin="branch-api@2.7.0">
    <data>
      <jenkins.branch.BranchSource>
        <source class="jenkins.plugins.git.GitSCMSource" plugin="git@4.11.0">
          <id>1234567890</id>
          <remote>https://github.com/elmorenox/eb-banking-deployment.git</remote>
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

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD create-job eb-banking-pipeline < job_config.xml

sudo chown -R jenkins:jenkins /var/lib/jenkins

# Output only the admin password
echo "Jenkins Admin Password: $ADMIN_PASSWORD"