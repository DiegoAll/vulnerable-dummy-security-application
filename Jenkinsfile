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
                    apt-get update && apt-get install -y golang-go curl
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
                    echo '🏗️ Instalando y ejecutando KICS CLI nativo...'

                    def exitCode = sh(
                        script: '''
                            # 1. Descarga del binario oficial si no existe en /tmp
                            if [ ! -x /tmp/kics ]; then
                                echo "Descargando binario oficial de KICS (v2.1.20)..."
                                curl -sSfL https://github.com/Checkmarx/kics/releases/download/v2.1.20/kics_2.1.20_linux_amd64.tar.gz -o /tmp/kics.tar.gz
                                tar -xzf /tmp/kics.tar.gz -C /tmp kics
                                chmod +x /tmp/kics
                                rm -f /tmp/kics.tar.gz
                            fi

                            # 2. Descarga e instalación de assets (queries y libraries) si no existen
                            if [ ! -d /tmp/kics-assets/queries ]; then
                                echo "Descargando reglas (queries) de KICS..."
                                curl -sSfL https://github.com/Checkmarx/kics/archive/refs/tags/v2.1.20.tar.gz -o /tmp/kics-src.tar.gz
                                mkdir -p /tmp/kics-src-extract
                                tar -xzf /tmp/kics-src.tar.gz -C /tmp/kics-src-extract
                                mkdir -p /tmp/kics-assets
                                cp -r /tmp/kics-src-extract/kics-2.1.20/assets/queries /tmp/kics-assets/
                                cp -r /tmp/kics-src-extract/kics-2.1.20/assets/libraries /tmp/kics-assets/
                                rm -rf /tmp/kics-src.tar.gz /tmp/kics-src-extract
                            fi

                            # 3. Ejecución del escaneo indicando las rutas de las queries
                            /tmp/kics scan \
                                -p . \
                                -o . \
                                --output-name kics-report \
                                --report-formats json,html \
                                --queries-path /tmp/kics-assets/queries \
                                --libraries-path /tmp/kics-assets/libraries || true
                        ''',
                        returnStatus: true
                    )

                    archiveArtifacts artifacts: 'kics-report.*', allowEmptyArchive: true

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