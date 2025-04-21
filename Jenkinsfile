pipeline {
  agent any
    stages {
        stage ('Build') {
            steps {
                sh '''#!/bin/bash
                python3.7 -m venv venv
                source venv/bin/activate
                pip install pip --upgrade
                pip install -r requirements.txt
                '''
            }
        }
        stage ('Test') {
            steps {
                sh '''#!/bin/bash
                chmod +x system_resources_test.sh
                ./system_resources_test.sh
                '''
            }
        }
        stage ('Deploy') {
            steps {
                sh '''#!/bin/bash
                # Make sure we're using the venv from this workspace
                if [ ! -d "venv" ]; then
                    echo "Creating virtual environment..."
                    python3.7 -m venv venv
                    source venv/bin/activate
                    pip install pip --upgrade
                    pip install -r requirements.txt
                else
                    source venv/bin/activate
                fi
                
                # Ensure EB CLI is available
                export PATH="/var/lib/jenkins/.ebcli-virtual-env/executables:$PATH"
                
                # Initialize EB if needed
                if [ ! -d ".elasticbeanstalk" ]; then
                    echo "Initializing Elastic Beanstalk..."
                    eb init -p python-3.7 ${EB_APP_NAME} --region us-east-1
                fi
                
                # Check if environment exists
                if eb status ${EB_ENV_NAME} 2>&1 | grep -q "No Environment"; then
                    # Create new environment if it doesn't exist
                    echo "Creating new Elastic Beanstalk environment: ${EB_ENV_NAME}"
                    eb create ${EB_ENV_NAME} --single
                else
                    # Deploy to existing environment
                    echo "Deploying to existing Elastic Beanstalk environment: ${EB_ENV_NAME}"
                    eb deploy ${EB_ENV_NAME}
                fi
                '''
            }
        }
    }
    
    environment {
        EB_ENV_NAME = "eb-ecommerce-env"
        EB_APP_NAME = "eb-ecommerce-app"
    }
    
    post {
        success {
            echo 'Successfully deployed application to AWS Elastic Beanstalk'
        }
        failure {
            echo 'Pipeline failed'
        }
    }
}