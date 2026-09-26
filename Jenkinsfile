pipeline {
    agent any

    environment {
        GOPATH = "${WORKSPACE}/.go"
        PATH   = "${GOPATH}/bin:/usr/local/go/bin:${env.PATH}"
    }

    stages {
        stage('Checkout Repository') {
            steps {
                git branch: 'main', 
                    url: 'https://github.com/DiegoAll/vulnerable-dummy-security-application.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'go mod download'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'go test -v -coverprofile=coverage.out ./...'
            }
        }

        stage('Security - Go Vuln Check') {
            steps {
                script {
                    echo '🔍 Instalando y ejecutando govulncheck...'
                    sh 'go install golang.org/x/vuln/cmd/govulncheck@latest'
                    sh 'govulncheck ./...'
                }
            }
        }

        stage('Build Artifact') {
            steps {
                echo '🔨 Compilando la aplicación Go...'
                sh 'go build -o api-service main.go'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}