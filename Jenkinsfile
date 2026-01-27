pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    CI = 'true'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Backend - Test') {
      steps {
        dir('backend/backend') {
          sh 'chmod +x mvnw'
          sh './mvnw -B test'
        }
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: 'backend/backend/target/surefire-reports/*.xml'
        }
      }
    }

    stage('Backend - Package') {
      steps {
        dir('backend/backend') {
          sh './mvnw -B -DskipTests package'
        }
      }
      post {
        success {
          archiveArtifacts artifacts: 'backend/backend/target/*.jar', fingerprint: true, allowEmptyArchive: true
        }
      }
    }

    stage('Frontend - Install') {
      steps {
        dir('frontend') {
          sh 'node -v'
          sh 'npm -v'
          sh 'npm ci'
        }
      }
    }

    stage('Frontend - Lint') {
      steps {
        dir('frontend') {
          sh 'npm run lint'
        }
      }
    }

    stage('Frontend - Build') {
      steps {
        dir('frontend') {
          sh 'npm run build'
        }
      }
      post {
        success {
          archiveArtifacts artifacts: 'frontend/dist/**', fingerprint: true, allowEmptyArchive: true
        }
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}
