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

        stage('Unit Tests, Coverage & Profiling') {
            steps {
                script {
                    echo '🧪 Instalando gotestsum...'
                    sh 'go install gotest.tools/gotestsum@latest'

                    echo '📊 Ejecutando pruebas unitarias, calculando cobertura y generando pprof...'
                    sh '''
                        ${GOPATH:-$HOME/go}/bin/gotestsum \
                            --junitfile unit-tests-report.xml \
                            --format testname \
                            -- ./... \
                            -coverprofile=coverage.out \
                            -cpuprofile=cpu.pprof \
                            -memprofile=mem.pprof

                        # Genera el reporte HTML interactivo de cobertura
                        go tool cover -html=coverage.out -o coverage.html

                        # Genera un resumen legible de cobertura por función en consola
                        go tool cover -func=coverage.out > coverage-summary.txt
                    '''
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'unit-tests-report.xml'
                    archiveArtifacts artifacts: 'coverage.html, coverage.out, coverage-summary.txt, *.pprof', allowEmptyArchive: true
                }
            }
        }

        stage('Security - SAST (Gosec)') {
            steps {
                script {
                    echo '🔒 Instalando y ejecutando Gosec (SAST)...'
                    sh 'go install github.com/securego/gosec/v2/cmd/gosec@latest'

                    def exitCode = sh(
                        script: '''
                            ${GOPATH:-$HOME/go}/bin/gosec -fmt=text -out=gosec-report.txt ./... || true
                            ${GOPATH:-$HOME/go}/bin/gosec -fmt=json -out=gosec-report.json ./... || true
                        ''',
                        returnStatus: true
                    )

                    archiveArtifacts artifacts: 'gosec-report.*', allowEmptyArchive: true

                    if (exitCode != 0) {
                        unstable('Gosec detectó hallazgos de seguridad en el código.')
                    }
                }
            }
        }

        stage('Security - SCA (Go Vuln Check)') {
            steps {
                script {
                    echo '🔍 Instalando y ejecutando govulncheck...'
                    sh 'go install golang.org/x/vuln/cmd/govulncheck@latest'
                    
                    def exitCode = sh(
                        script: '''
                            ${GOPATH:-$HOME/go}/bin/govulncheck -json ./... > govulncheck-report.json || true
                            ${GOPATH:-$HOME/go}/bin/govulncheck ./... > govulncheck-report.txt
                        ''',
                        returnStatus: true
                    )
                    
                    archiveArtifacts artifacts: 'govulncheck-report.*', allowEmptyArchive: true

                    if (exitCode != 0) {
                        unstable('govulncheck encontró vulnerabilidades en las dependencias.')
                    }
                }
            }
        }

        stage('Security - IaC Scan (KICS)') {
            steps {
                script {
                    echo '🏗️ Ejecutando KICS para escaneo de IaC (Dockerfile/K8s)...'
                    
                    // Asegura la disponibilidad de la imagen
                    sh 'docker pull checkmarx/kics:latest || true'

                    def exitCode = sh(
                        script: '''
                            # Crea un directorio específico para los resultados
                            mkdir -p kics-out

                            # Monta el directorio actual mediante la ruta relativa '.'
                            docker run --rm \
                                -v .:/path \
                                checkmarx/kics:latest scan \
                                -p /path \
                                -o /path/kics-out \
                                --output-name kics-report \
                                --report-formats json,txt || true
                        ''',
                        returnStatus: true
                    )

                    // Archiva los reportes generados dentro de kics-out
                    archiveArtifacts artifacts: 'kics-out/kics-report.*', allowEmptyArchive: true

                    if (exitCode != 0) {
                        unstable('KICS detectó observaciones de seguridad en la infraestructura.')
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