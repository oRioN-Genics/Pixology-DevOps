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
          sh(label: 'Backend tests with Mongo (Docker network)', script: '''#!/bin/bash
            set -euo pipefail
            
            # Generate a clean name for Docker resources
            CLEAN_TAG=$(echo "${BUILD_TAG}" | tr -cs 'a-zA-Z0-9_.-' '-')
            NAME="pixology-mongo-${CLEAN_TAG}"
            NET="pixology-ci-${CLEAN_TAG}"
            
            echo "Creating network: $NET"
            docker network create "$NET" >/dev/null 2>&1 || true
            
            echo "Starting MongoDB container: $NAME"
            docker rm -f "$NAME" >/dev/null 2>&1 || true
            docker run -d --name "$NAME" --network "$NET" mongo:7
            
            echo "Waiting for MongoDB to be ready..."
            attempt=0
            until docker exec "$NAME" mongosh --quiet --eval "db.runCommand({ ping: 1 }).ok" | grep -q "1" || [ $attempt -eq 30 ]; do
              sleep 2
              attempt=$((attempt + 1))
            done

            if [ $attempt -eq 30 ]; then
              echo "ERROR: MongoDB did not become ready in time"
              docker logs "$NAME"
              exit 1
            fi

            echo "Running Maven tests inside Docker container..."
            # Using -u $(id -u) ensures files created in /target belong to Jenkins user, not root
            docker run --rm \
              --network "$NET" \
              -u $(id -u):$(id -g) \
              -e MONGO_URI="mongodb://$NAME:27017/pixology_test" \
              -e MONGO_DATABASE="pixology_test" \
              -v "$PWD":/workspace \
              -v "$HOME/.m2":/var/maven/.m2 \
              -e MAVEN_CONFIG=/var/maven/.m2 \
              -w /workspace \
              maven:3.9-eclipse-temurin-21 \
              mvn -Duser.home=/var/maven -B test
          ''')
        }
      }
      post {
        always {
          sh(label: 'Cleanup Docker Resources', script: '''#!/bin/bash
            CLEAN_TAG=$(echo "${BUILD_TAG}" | tr -cs 'a-zA-Z0-9_.-' '-')
            NAME="pixology-mongo-${CLEAN_TAG}"
            NET="pixology-ci-${CLEAN_TAG}"
            docker rm -f "$NAME" >/dev/null 2>&1 || true
            docker network rm "$NET" >/dev/null 2>&1 || true
          ''')
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
          sh '''#!/bin/bash
            set -euo pipefail
            docker run --rm \
              -u $(id -u):$(id -g) \
              -e HOME=/workspace \
              -e npm_config_cache=/workspace/.npm \
              -v "$PWD":/workspace \
              -w /workspace \
              node:20-bullseye \
              bash -lc "mkdir -p /workspace/.npm && node -v && npm -v && npm ci"
          '''
        }
      }
    }

    stage('Frontend - Lint') {
      steps {
        dir('frontend') {
          sh '''#!/bin/bash
            set -euo pipefail
            docker run --rm \
              -u $(id -u):$(id -g) \
              -e HOME=/workspace \
              -e npm_config_cache=/workspace/.npm \
              -v "$PWD":/workspace \
              -w /workspace \
              node:20-bullseye \
              bash -lc "mkdir -p /workspace/.npm && npm run lint"
          '''
        }
      }
    }

    stage('Frontend - Build') {
      steps {
        dir('frontend') {
          sh '''#!/bin/bash
            set -euo pipefail
            docker run --rm \
              -u $(id -u):$(id -g) \
              -e HOME=/workspace \
              -e npm_config_cache=/workspace/.npm \
              -v "$PWD":/workspace \
              -w /workspace \
              node:20-bullseye \
              bash -lc "mkdir -p /workspace/.npm && npm run build"
          '''
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
