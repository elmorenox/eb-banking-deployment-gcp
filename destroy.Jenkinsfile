pipeline {
  agent any
  stages {
    stage('Initialize') {
      steps {
        script {
          // Get the GCP project ID automatically
          env.GCP_PROJECT_ID = sh(script: 'gcloud config get-value project', returnStdout: true).trim()
          echo "Detected GCP Project ID: ${env.GCP_PROJECT_ID}"
          
          // Get the most recent deployed version (or use parameter)
          env.APP_VERSION = params.VERSION_TO_DESTROY ?: sh(
            script: 'gcloud app versions list --sort-by="~version.createTime" --limit=1 --format="value(version.id)"',
            returnStdout: true
          ).trim()
          
          echo "Preparing to destroy version: ${env.APP_VERSION}"
        }
      }
    }
    
    stage('Destroy App Engine Deployment') {
      steps {
        script {
          try {
            // Stop and delete the App Engine version
            sh """
            gcloud app versions delete ${APP_VERSION} \
              --project=${GCP_PROJECT_ID} \
              --service=${APP_SERVICE} \
              --quiet
            """
            
            echo "Successfully deleted version ${APP_VERSION} from service ${APP_SERVICE}"
          } catch (Exception e) {
            echo "Warning: Failed to delete version ${APP_VERSION} - ${e.message}"
          }
        }
      }
    }
    
    stage('Cleanup Related Resources') {
      steps {
        script {
          // Cleanup Cloud Storage buckets created for this version
          sh """
          gsutil ls gs://${GCP_PROJECT_ID}.appspot.com/${APP_SERVICE}/${APP_VERSION}/ | \
          xargs -I {} gsutil rm -r {}
          """
          
          echo "Cleaned up storage resources for version ${APP_VERSION}"
        }
      }
    }
  }
  
  environment {
    GCP_REGION = "us-east1"
    APP_SERVICE = "banking-app"
  }
  
  parameters {
    string(
      name: 'VERSION_TO_DESTROY',
      description: '(Optional) Specific version to destroy. Leave blank for most recent.',
      defaultValue: '',
      trim: true
    )
  }
  
  post {
    success {
      echo "Successfully destroyed App Engine version ${APP_VERSION} and related resources"
    }
    failure {
      echo "Failed to completely destroy resources. Manual cleanup may be required."
    }
  }
}