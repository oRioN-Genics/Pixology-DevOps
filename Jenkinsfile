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
          sh(label: 'Backend tests with Mongo (Docker network)', script: '''
            set -euo pipefail

            CLEAN_TAG=$(echo "${BUILD_TAG}" | tr -cs 'a-zA-Z0-9_.-' '-')
            NAME="pixology-mongo-${CLEAN_TAG}"
            NET="pixology-ci-${CLEAN_TAG}"

            echo "Creating network: $NET"
            docker network create "$NET" >/dev/null 2>&1 || true

            echo "Starting MongoDB container: $NAME"
            docker rm -f "$NAME" >/dev/null 2>&1 || true
            docker run -d --name "$NAME" --network "$NET" mongo:7 >/dev/null

            echo "Waiting for MongoDB..."
            attempt=0
            until docker exec "$NAME" mongosh --quiet --eval "db.runCommand({ ping: 1 }).ok" | grep -q "1" || [ $attempt -eq 30 ]; do
              sleep 1
              attempt=$((attempt + 1))
            done

            if [ $attempt -eq 30 ]; then
              echo "MongoDB did not become ready in time"
              docker logs "$NAME" || true
              exit 1
            fi

            # Run Maven INSIDE Docker on the SAME network so $NAME resolves
            docker run --rm \
              --network "$NET" \
              -e MONGO_URI="mongodb://$NAME:27017/pixology_test" \
              -e MONGO_DATABASE="pixology_test" \
              -v "$PWD":/workspace \
              -w /workspace \
              maven:3.9-eclipse-temurin-21 \
              mvn -B test
          ''')
        }
      }
      post {
        always {
          sh '''
            CLEAN_TAG=$(echo "${BUILD_TAG}" | tr -cs 'a-zA-Z0-9_.-' '-')
            NAME="pixology-mongo-${CLEAN_TAG}"
            NET="pixology-ci-${CLEAN_TAG}"

            docker rm -f "$NAME" >/dev/null 2>&1 || true
            docker network rm "$NET" >/dev/null 2>&1 || true
          '''
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
