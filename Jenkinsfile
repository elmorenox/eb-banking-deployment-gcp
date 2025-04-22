pipeline {
  agent any
  stages {
    stage ('Build') {
      steps {
        sh '''#!/bin/bash
        # Use python3.10 explicitly
        PYTHON_PATH=$(which python3.10)
        echo "Using Python at: $PYTHON_PATH"
        
        # Create virtual environment
        $PYTHON_PATH -m venv venv
        . venv/bin/activate
        
        pip install pip --upgrade
        pip install -r requirements.txt
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
        . venv/bin/activate
        
        # Initialize EB CLI using our config file
        if [ ! -d ".elasticbeanstalk" ]; then
          echo "Setting up Elastic Beanstalk configuration..."
          mkdir -p .elasticbeanstalk
          cp eb-config.yml .elasticbeanstalk/config.yml
        fi
        
        echo "Deploying to Elastic Beanstalk..."
        eb deploy ${EB_ENV_NAME} || eb create ${EB_ENV_NAME} --single --instance_type t3.micro
        '''
      }
    }
  }
  environment {
    EB_ENV_NAME = "eb-banking-env"
    EB_APP_NAME = "eb-banking-app"
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