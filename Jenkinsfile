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
          sh(label: 'Backend tests with Mongo', script: '''
            # Generate a clean name using standard tools
            CLEAN_TAG=$(echo "${BUILD_TAG}" | tr -cs 'a-zA-Z0-9_.-' '-')
            NAME="pixology-mongo-${CLEAN_TAG}"

            echo "Starting MongoDB container: $NAME"
            docker rm -f "$NAME" >/dev/null 2>&1 || true
            docker run -d --name "$NAME" -p 27017:27017 mongo:7

            # Wait for Mongo
            echo "Waiting for MongoDB..."
            attempt=0
            until docker exec "$NAME" mongosh --quiet --eval "db.runCommand({ ping: 1 }).ok" | grep -q "1" || [ $attempt -eq 30 ]; do
              sleep 1
              attempt=$((attempt + 1))
            done

            export MONGO_URI="mongodb://localhost:27017"
            export MONGO_DATABASE="pixology_test"

            mvn -B test
          ''')
        }
      }
      post {
        always {
          // Use the same logic here or just kill by name pattern
          sh 'docker ps -a -q --filter "name=pixology-mongo-" | xargs -r docker rm -f'
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
