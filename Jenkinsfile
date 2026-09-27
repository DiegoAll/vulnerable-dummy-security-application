pipeline {
    agent any

    environment {
        GO_VERSION  = '1.23.2'
        GOROOT      = "${WORKSPACE}/go"
        GOPATH      = "${WORKSPACE}/gopath"
        PATH        = "${WORKSPACE}/go/bin:${WORKSPACE}/gopath/bin:${env.PATH}"
        GOTOOLCHAIN = 'local'
        CGO_ENABLED = '0'
    }

    stages {
        stage('Checkout Repository') {
            steps {
                git branch: 'main', 
                    url: 'https://github.com/DiegoAll/vulnerable-dummy-security-application.git'
            }
        }

        stage('Setup Go Environment') {
            steps {
                script {
                    echo "📦 Configurando entorno Go ${GO_VERSION}..."
                    sh '''
                        if [ ! -d "$GOROOT" ]; then
                            curl -sL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o go.tar.gz
                            mkdir -p $GOROOT
                            tar -C $GOROOT --strip-components=1 -xzf go.tar.gz
                            rm go.tar.gz
                        fi
                        mkdir -p $GOPATH/bin
                        go version
                    '''
                }
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