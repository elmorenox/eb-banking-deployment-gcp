pipeline {
  agent any
    stages {
        stage ('Build') {
            steps {
                sh '''#!/bin/bash
                # Find python3.7 path
                PYTHON_PATH=$(which python3.7 || which python3)
                echo "Using Python at: $PYTHON_PATH"
                
                # Create virtual environment
                $PYTHON_PATH -m venv venv || python3 -m venv venv
                
                # Activate virtual environment
                . venv/bin/activate || source venv/bin/activate
                
                pip install pip --upgrade
                pip install -r requirements.txt
                
                # Install EB CLI in the virtual environment
                pip install awsebcli
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
                # Activate virtual environment
                . venv/bin/activate || source venv/bin/activate
                
                # Initialize Elastic Beanstalk if needed
                if [ ! -d ".elasticbeanstalk" ]; then
                    echo "Initializing Elastic Beanstalk..."
                    eb init -p python-3.7 ${EB_APP_NAME} --region us-east-1
                fi
                
                # Deploy to Elastic Beanstalk
                echo "Deploying to Elastic Beanstalk environment: ${EB_ENV_NAME}"
                eb deploy ${EB_ENV_NAME} --staged || eb create ${EB_ENV_NAME} --single
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