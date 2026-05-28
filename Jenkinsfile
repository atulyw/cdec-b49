pipeline {
  agent {
    label 'terraform'
  }
  parameters {
    choice(
      name: 'ENVIRONMENT',
      choices: ['dev', 'test', 'prod'],
      description: 'Terraform environment folder under terraform/environments/'
    )
  }

  options {
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  environment {
    TF_DIR = "terraform/environments/${params.ENVIRONMENT}"
  }

  stages {

    stage('Checkout Code') {
      steps {
        git url: 'https://github.com/atulyw/cdec-b49.git', branch: 'terraform-v2'
      }
    }

    stage('Terraform Version') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding', 
          credentialsId: 'aws-creds', 
          accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {
          sh 'terraform version'
          sh 'aws --version'
          sh 'aws s3 ls'
        }
      }
    }

    stage('Terraform Init') {
      steps {
        dir("${env.TF_DIR}") {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding', 
            credentialsId: 'aws-creds', 
            accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
          ]]) {
            sh 'terraform init -input=false'
          }
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir("${env.TF_DIR}") {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding', 
            credentialsId: 'aws-creds', 
            accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
          ]]) {
            sh 'terraform plan -input=false -out=tfplan'
          }
        }
      }
    }

    stage('Manual Approval') {
      steps {
        input message: "Review the Terraform Plan log above. Apply to ${params.ENVIRONMENT}?", ok: 'Apply'
      }
    }

    stage('Terraform Apply') {
      steps {
        dir("${env.TF_DIR}") {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding', 
            credentialsId: 'aws-creds', 
            accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
          ]]) {
            sh 'terraform apply -input=false -auto-approve tfplan'
          }
        }
      }
    }
  }

  post {
    success {
      echo "SUCCESS: ${params.ENVIRONMENT} infrastructure deployed from branch terraform-v2."
      echo "Next: aws eks update-kubeconfig --region ap-south-1 --name cdec-${params.ENVIRONMENT}-eks"
    }
    failure {
      echo 'FAILURE: Pipeline failed. Check the failed stage log.'
    }
    always {
      echo 'Build finished. Cleaning workspace...'
      deleteDir()
    }
  }
}
