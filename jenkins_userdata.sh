#!/bin/bash
# Fully automated Jenkins setup script for CI/CD pipeline with Google App Engine

# Update system packages
sudo apt update -y
sudo apt upgrade -y

# Install required system packages
sudo apt install -y openjdk-17-jdk git python3 python3-pip python3-venv unzip software-properties-common expect

# Configure Jenkins repository and install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Verify Google Cloud SDK is installed (should be on Compute Engine VMs)
if ! command -v gcloud &> /dev/null; then
    echo "Installing Google Cloud SDK..."
    # Add Google Cloud SDK repository
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    sudo apt update
    sudo apt install -y google-cloud-sdk
else
    echo "Google Cloud SDK already installed"
fi

# Make sure the Jenkins user can access gcloud
sudo -u jenkins gcloud auth list || true

# Ensure Jenkins user can access application default credentials
sudo mkdir -p /var/lib/jenkins/.config/gcloud
sudo ln -sf /etc/google-cloud/application_default_credentials.json /var/lib/jenkins/.config/gcloud/application_default_credentials.json
sudo chown -R jenkins:jenkins /var/lib/jenkins/.config

# Wait for Jenkins to be fully initialized
echo "Waiting for Jenkins to initialize..."
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
echo "Downloading Jenkins CLI..."
cd /tmp
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Install required Jenkins plugins
echo "Installing Jenkins plugins..."
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD install-plugin workflow-aggregator git junit pipeline-stage-view blueocean docker-workflow pipeline-github-lib pipeline-rest-api ssh-agent google-oauth-plugin google-source-plugin google-storage-plugin google-container-registry-auth -deploy

# Wait for plugins to be installed
sleep 60

# Create Multibranch Pipeline job
echo "Creating Jenkins pipeline job..."
cat > job_config.xml << 'EOL'
<?xml version='1.1' encoding='UTF-8'?>
<org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject plugin="workflow-multibranch@2.26">
  <actions/>
  <description></description>
  <properties>
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

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD create-job app-engine-pipeline < job_config.xml

echo "Jenkins Admin Password: $ADMIN_PASSWORD"
echo "Jenkins setup completed! See /home/ubuntu/jenkins-readme.txt for details."