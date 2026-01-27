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
          sh '''
            set -e

            echo "Starting MongoDB container..."
            docker rm -f pixology-mongo >/dev/null 2>&1 || true
            docker run -d --name pixology-mongo -p 27017:27017 mongo:7

            echo "Waiting for MongoDB to be ready..."
            for i in $(seq 1 30); do
              if docker exec pixology-mongo mongosh --quiet --eval "db.runCommand({ ping: 1 }).ok" | grep -q "1"; then
                echo "MongoDB is ready"
                break
              fi
              sleep 1
            done

            echo "Running tests with CI Mongo settings..."
            export MONGO_URI="mongodb://localhost:27017"
            export MONGO_DATABASE="pixology_test"

            mvn -B test
          '''
        }
      }
      post {
        always {
          sh 'docker rm -f pixology-mongo >/dev/null 2>&1 || true'
          junit allowEmptyResults: true, testResults: 'backend/backend/target/surefire-reports/*.xml'
        }
      }
    }

    stage('Backend - Package') {
      steps {
        dir('backend/backend') {
          sh 'mvn -B -DskipTests package'
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
