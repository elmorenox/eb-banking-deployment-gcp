pipeline {
  agent any
  
  stages {
    stage('Verify Environment') {
      steps {
        script {
          // Confirm we're destroying the correct project
          env.GCP_PROJECT_ID = sh(script: 'gcloud config get-value project', returnStdout: true).trim()
          echo "🚨 Preparing to DESTROY ALL TERRAFORM-MANAGED RESOURCES in project: ${env.GCP_PROJECT_ID}"
          
          // Verify Terraform is installed
          sh 'terraform version'
        }
      }
    }
    
    stage('Terraform Destroy') {
      steps {
        dir('terraform') {  // Change this if your Terraform files are in a different directory
          script {
            // Destroy with auto-approval and detailed logging
            sh '''
            terraform destroy -auto-approve \
              -var "project_id=${GCP_PROJECT_ID}" \
              -var "app_version=${BUILD_NUMBER}"  # Optional: Pass the same vars as your create pipeline
            '''
          }
        }
      }
    }
  }
  
  environment {
    // Optional: Reuse the same vars from your create pipeline
    GCP_REGION = "us-east1"  
    APP_SERVICE = "banking-app"
  }
  
  options {
    timeout(time: 30, unit: 'MINUTES')  // Prevent hangs
  }
  
  post {
    success {
      echo '✅ Successfully destroyed all Terraform-managed resources'
    }
    failure {
      echo '❌ Destruction failed! Check logs and verify resources manually.'
      // Optional: Send failure notification
    }
    always {
      cleanWs()  // Clean up workspace files
    }
  }
}