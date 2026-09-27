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
                    // Muestra el dashboard nativo y gráficos de tendencia de tests en Jenkins
                    junit allowEmptyResults: true, testResults: 'unit-tests-report.xml'

                    // Archiva el HTML de cobertura, el resumen en texto y los archivos pprof para profiling
                    archiveArtifacts artifacts: 'coverage.html, coverage.out, coverage-summary.txt, *.pprof', allowEmptyArchive: true
                }
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