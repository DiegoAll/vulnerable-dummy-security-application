pipeline {
    agent any

    environment {
        IMAGE_NAME = 'vulnerable-dummy-security-application'
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Repository') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/DiegoAll/vulnerable-dummy-security-application.git'
            }
        }

        stage('Security - Secret Scanning (Gitleaks)') {
            steps {
                script {
                    echo '🔑 Instalando y ejecutando Gitleaks...'

                    def exitCode = sh(
                        script: '''
                            if [ ! -x /tmp/gitleaks ]; then
                                echo "Descargando binario oficial de Gitleaks..."
                                curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz -o /tmp/gitleaks.tar.gz
                                tar -xzf /tmp/gitleaks.tar.gz -C /tmp gitleaks
                                chmod +x /tmp/gitleaks
                                rm -f /tmp/gitleaks.tar.gz
                            fi

                            /tmp/gitleaks git \
                                --report-format json \
                                --report-path gitleaks-report.json \
                                --exit-code 1 \
                                . || true
                        ''',
                        returnStatus: true
                    )

                    archiveArtifacts artifacts: 'gitleaks-report.*', allowEmptyArchive: true

                    if (exitCode != 0) {
                        unstable('Gitleaks detectó posibles secretos en el historial de git.')
                    }
                }
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

                        go tool cover -html=coverage.out -o coverage.html
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
                            if [ ! -x /tmp/kics ]; then
                                echo "Descargando binario oficial de KICS (v2.1.20)..."
                                curl -sSfL https://github.com/Checkmarx/kics/releases/download/v2.1.20/kics_2.1.20_linux_amd64.tar.gz -o /tmp/kics.tar.gz
                                tar -xzf /tmp/kics.tar.gz -C /tmp kics
                                chmod +x /tmp/kics
                                rm -f /tmp/kics.tar.gz
                            fi

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

        stage('Build Docker Image') {
            steps {
                echo '🐳 Construyendo la imagen Docker...'
                sh '''
                    if ! command -v docker >/dev/null 2>&1; then
                        echo "ERROR: el CLI de Docker no está disponible en este agente Jenkins."
                        echo "Se necesita el socket de Docker montado (docker.sock) y el binario docker instalado."
                        exit 1
                    fi

                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Security - SBOM (Syft)') {
            steps {
                script {
                    echo '📦 Instalando Syft y generando el SBOM de la imagen...'

                    sh '''
                        if [ ! -x /tmp/syft ]; then
                            echo "Descargando binario oficial de Syft..."
                            curl -sSfL https://github.com/anchore/syft/releases/download/v1.52.0/syft_1.52.0_linux_amd64.tar.gz -o /tmp/syft.tar.gz
                            tar -xzf /tmp/syft.tar.gz -C /tmp syft
                            chmod +x /tmp/syft
                            rm -f /tmp/syft.tar.gz
                        fi

                        /tmp/syft scan docker:${IMAGE_NAME}:${IMAGE_TAG} \
                            -o syft-json=sbom.syft.json \
                            -o cyclonedx-json=sbom.cdx.json
                    '''

                    archiveArtifacts artifacts: 'sbom.*.json', allowEmptyArchive: true
                }
            }
        }

        stage('Security - Container Scan (Grype)') {
            steps {
                script {
                    echo '🛡️ Instalando Grype y escaneando el SBOM en busca de vulnerabilidades...'

                    def exitCode = sh(
                        script: '''
                            if [ ! -x /tmp/grype ]; then
                                echo "Descargando binario oficial de Grype..."
                                curl -sSfL https://github.com/anchore/grype/releases/download/v0.119.0/grype_0.119.0_linux_amd64.tar.gz -o /tmp/grype.tar.gz
                                tar -xzf /tmp/grype.tar.gz -C /tmp grype
                                chmod +x /tmp/grype
                                rm -f /tmp/grype.tar.gz
                            fi

                            /tmp/grype sbom:sbom.syft.json -o json --file grype-report.json --fail-on medium
                            EXIT=$?
                            /tmp/grype sbom:sbom.syft.json -o table --file grype-report.txt || true
                            exit $EXIT
                        ''',
                        returnStatus: true
                    )

                    archiveArtifacts artifacts: 'grype-report.*', allowEmptyArchive: true

                    if (exitCode != 0) {
                        unstable('Grype detectó vulnerabilidades de severidad media o mayor en la imagen.')
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs(notFailBuild: true)
        }
    }
}
