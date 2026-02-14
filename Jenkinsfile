pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    CI = 'true'
    REGISTRY = "ghcr.io"
    GITHUB_USER = 'oRioN-Genics' 
    BACKEND_IMAGE = "ghcr.io/orion-genics/pixology-backend"
    FRONTEND_IMAGE = "ghcr.io/orion-genics/pixology-frontend"
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
          sh(label: 'Backend tests with Mongo', script: '''#!/bin/bash
            set -euo pipefail
            CLEAN_TAG=$(echo "${BUILD_TAG}" | tr -cs 'a-zA-Z0-9_.-' '-')
            NAME="pixology-mongo-${CLEAN_TAG}"
            NET="pixology-ci-${CLEAN_TAG}"

            docker network create "$NET" >/dev/null 2>&1 || true
            docker rm -f "$NAME" >/dev/null 2>&1 || true
            docker run -d --name "$NAME" --network "$NET" mongo:7

            attempt=0
            until docker exec "$NAME" mongosh --quiet --eval "db.runCommand({ ping: 1 }).ok" | grep -q "1" || [ $attempt -eq 30 ]; do
              sleep 2
              attempt=$((attempt + 1))
            done

            if [ $attempt -eq 30 ]; then exit 1; fi

            docker run --rm --network "$NET" -u $(id -u):$(id -g) \
              -e MONGO_URI="mongodb://$NAME:27017/pixology_test" \
              -e MONGO_DATABASE="pixology_test" -v "$PWD":/workspace \
              -v "$HOME/.m2":/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2 \
              -w /workspace maven:3.9-eclipse-temurin-21 mvn -Duser.home=/var/maven -B test
          ''')
        }
      }
      post {
        always {
          sh(label: 'Cleanup Docker Resources', script: '''#!/bin/bash
            CLEAN_TAG=$(echo "${BUILD_TAG}" | tr -cs 'a-zA-Z0-9_.-' '-')
            docker rm -f "pixology-mongo-${CLEAN_TAG}" >/dev/null 2>&1 || true
            docker network rm "pixology-ci-${CLEAN_TAG}" >/dev/null 2>&1 || true
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
        retry(3) {
          dir('frontend') {
            sh '''#!/bin/bash
              set -euo pipefail
              docker run --rm -u $(id -u):$(id -g) -e HOME=/workspace \
                -e npm_config_cache=/workspace/.npm -e NPM_CONFIG_USERCONFIG=/workspace/.npmrc \
                -v "$PWD":/workspace -w /workspace node:20-bullseye \
                bash -lc "mkdir -p /workspace/.npm && npm ci"
            '''
          }
        }
      }
    }

    stage('Frontend - Build') {
      steps {
        dir('frontend') {
          sh '''#!/bin/bash
            set -euo pipefail
            docker run --rm -u $(id -u):$(id -g) -e HOME=/workspace \
              -e npm_config_cache=/workspace/.npm \
              -v "$PWD":/workspace -w /workspace node:20-bullseye \
              bash -lc "rm -rf node_modules && npm ci && npm run build"
          '''
        }
      }
    }

    stage('Docker - Build & Push') {
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: 'ghcr-creds', 
                                       usernameVariable: 'GH_USER', 
                                       passwordVariable: 'GH_TOKEN')]) {
            sh "echo ${GH_TOKEN} | docker login ${REGISTRY} -u ${GH_USER} --password-stdin"
          }
          
          dir('backend/backend') {
            sh "docker build -t ${BACKEND_IMAGE}:latest -t ${BACKEND_IMAGE}:${BUILD_NUMBER} ."
            retry(3) {
              sh "docker push ${BACKEND_IMAGE}:latest"
              sh "docker push ${BACKEND_IMAGE}:${BUILD_NUMBER}"
            }
          }

          dir('frontend') {
            sh "docker build -t ${FRONTEND_IMAGE}:latest -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} ."
            retry(3) {
              sh "docker push ${FRONTEND_IMAGE}:latest"
              sh "docker push ${FRONTEND_IMAGE}:${BUILD_NUMBER}"
            }
          }
        }
      }
    }

    stage('Debug - Jenkins Public IP') {
      steps {
        sh '''#!/bin/bash
          set -euo pipefail
          echo -n "Jenkins public IP: "
          curl -s https://api.ipify.org
          echo
        '''
      }
    }

    stage('Deploy to EC2') {
      when { branch 'main' }
      steps {
        sshagent(credentials: ['pixology-ec2-ssh']) {
          sh '''#!/bin/bash
            set -euo pipefail
            EC2_HOST="65.0.4.209"
            APP_DIR="/home/ubuntu/pixology/repo"
            SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

            ssh $SSH_OPTS ubuntu@$EC2_HOST "
              cd $APP_DIR &&
              git pull &&
              docker compose -f docker-compose.ec2.yml pull &&
              docker compose -f docker-compose.ec2.yml up -d
            "
          '''
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