pipeline {
  agent any
  stages {
    stage ('Initialize') {
      steps {
        script {
          // Get the GCP project ID automatically using gcloud
          env.GCP_PROJECT_ID = sh(script: 'gcloud config get-value project', returnStdout: true).trim()
          echo "Detected GCP Project ID: ${env.GCP_PROJECT_ID}"
          
          // Set the app version based on the build number
          env.APP_VERSION = "v-${BUILD_NUMBER}"
          echo "Using app version: ${env.APP_VERSION}"
        }
      }
    }
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
        echo "Deploying to App Engine Flexible Environment in project: ${GCP_PROJECT_ID}..."
        
        # Check if App Engine application already exists
        if ! gcloud app describe --project=${GCP_PROJECT_ID} >/dev/null 2>&1; then
          echo "App Engine application not found, creating..."
          gcloud app create --project=${GCP_PROJECT_ID} --region=${GCP_REGION}
        else
          echo "App Engine application already exists"
        fi
        
        # Proceed with deployment
        gcloud app deploy app.yaml --project=${GCP_PROJECT_ID} --version=${APP_VERSION} --verbosity=debug

        VERSION_STATUS=$(gcloud app versions describe ${APP_VERSION} --format="value(servingStatus)")

        # If it exists but isn't serving, start it manually
        if [ -n "$VERSION_STATUS" ]; then
          gcloud app versions start ${APP_VERSION}
        fi
        '''
      }
    }
  }
  environment {
    GCP_REGION = "us-east1"
    APP_SERVICE = "banking-app"
  }
  post {
    success {
      echo 'Successfully deployed application to App Engine Flexible Environment'
    }
    failure {
      echo 'Pipeline failed'
    }
  }
}