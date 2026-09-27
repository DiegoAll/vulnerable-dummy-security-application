pipeline {
    agent any

    stages {
        stage('Checkout Repository') {
            steps {
                git branch: 'main', 
                    url: 'https://github.com/DiegoAll/vulnerable-dummy-security-application.git'
            }
        }

        stage('Setup Go Environment') {
            steps {
                sh '''
                    apt-get update && apt-get install -y golang-go
                    go version
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'go mod download'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'go test -v ./...'
            }
        }

        stage('Security - Go Vuln Check') {
            steps {
                script {
                    echo '🔍 Instalando y ejecutando govulncheck...'
                    sh 'go install golang.org/x/vuln/cmd/govulncheck@latest'
                    
                    // Ejecuta govulncheck capturando la salida en texto y JSON
                    def exitCode = sh(
                        script: '''
                            ${GOPATH:-$HOME/go}/bin/govulncheck -json ./... > govulncheck-report.json || true
                            ${GOPATH:-$HOME/go}/bin/govulncheck ./... > govulncheck-report.txt
                        ''',
                        returnStatus: true
                    )
                    
                    // Archiva los reportes como artefactos descargables en Jenkins
                    archiveArtifacts artifacts: 'govulncheck-report.*', allowEmptyArchive: true

                    // Si se encontraron vulnerabilidades, marca el stage/build como UNSTABLE (amarillo)
                    if (exitCode != 0) {
                        unstable('govulncheck encontró vulnerabilidades — consulta los artefactos descargables.')
                    }
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
            cleanWs(notFailBuild: true)
        }
    }
}