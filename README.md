# vulnerable-dummy-security-application

Vulnerable dummy security application



https://cloud.google.com/workforce-identity-federation?hl=es_419

        CONTAINER ID   NAME      CPU %    MEM USAGE / LIMIT      MEM %    NET I/O          BLOCK I/O        PIDS
    8bc7bd60ab47   jenkins   0.15%    1.563GiB / 62.43GiB    2.50%    964MB / 32MB     262MB / 7.19GB   84


El dato que más llama la atención ahí es el Block I/O de escritura: 7.19 GB — es bastante alto comparado con los otros contenedores (que están en el rango de MB). Tiene sentido dado el volumen de builds que has corrido (24 builds del pipeline, cada uno generando logs, reports, SBOMs, artifacts de varios MB), pero si en algún momento notas que el disco se llena más rápido de lo esperado, ese acumulado de escrituras en jenkins_home/jobs/*/builds/*/archive/ es el primer lugar donde mirar — es exactamente lo que se beneficiaría de una política de retención de builds antiguos (Jenkins tiene una opción nativa para eso: "Discard old builds" en la configuración del job).



memcache.go:265] couldn't get current server API group list: Get "https://35.196.65.122/api?timeout=32s": context deadline exceeded


GET [https://35.196.65.122/api/v1/namespaces/default/pods?limit=500](https://35.196.65.122/api/v1/namespaces/default/pods?limit=500)

kubectl get pods -v=8
kubectl config get-contexts
more /home/diegoall/.kube/config
ls -la ~/.kube/config
kubectl config view --raw


2. El segundo intento (Por qué funcionó rápido de inmediato)

En el segundo intento con -v=8 (y en los comandos posteriores):

kubectl guardó en su caché local (~/.kube/cache) o saltó el descubrimiento global temporalmente. Fue directamente a consultar el endpoint /api/v1/namespaces/default/pods.

Tardó apenas 300 ms (200 OK) y respondió instantáneamente mostrando No resources found in default namespace.

Causa raíz técnica en tu clúster (diego-cluster)
Revisando el manifiesto de Terraform con el que desplegaste el clúster:

Especificaciones de hardware (e2-small + Spot):

Los nodos e2-small tienen 0.5 vCPU y 2 GB de RAM.

Al ser nodos Spot, GCP puede reclamar e intercambiar capacidad, y los recursos son más limitados.

Carga en el Control Plane / API Server:

En GKE Zonal (us-east1-b), el Control Plane comparte recursos gestionados. Si el API Server o etcd estaban respondiendo lento a la petición de discovery (o si la resolución inicial tuvo latencia de red momentánea), la consulta general /api expiró.

Comportamiento del Discovery Cache de kubectl:

Si la caché expiró o estaba vacía en ~/.kube/cache, kubectl se bloqueó esperando la respuesta del esquema completo. Una vez que esa etapa falló y se sobrepasó, los queries individuales a los recursos funcionaron en milisegundos.

Solución preventiva si te vuelve a ocurrir
Si kubectl vuelve a quedarse "colgado" buscando la lista de APIs, puedes limpiar la caché local para forzar a que reescriba el esquema limpio.

# Limpia la caché de descubrimiento local de kubectl

    rm -rf ~/.kube/cache/


Si notas que los tiempos de respuesta del API Server siguen fluctuando mucho, considera cambiar la variable machine_type en tu Terraform de e2-small a e2-medium (1 vCPU, 4 GB RAM) para darle más holgura a los componentes del nodo


Google Cloud

    gcloud auth login --no-launch-browser


Problemas bacrim

    sudo ip link set dev wlo1 mtu 1350
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1



¿Para qué sirve? Es una herramienta de diagnóstico de bajo nivel. Te lo sugerí justo porque estabas teniendo problemas de red (el ajuste de MTU/IPv6 que hiciste) — con --log-http puedes ver exactamente en qué punto se cuelga la comunicación: si el request nunca sale, si Google responde con un error HTTP específico (403, 429, 500), o si la conexión se corta a medio camino. Sin ese flag, un comando colgado solo te muestra silencio, sin pista de qué está pasando.

¿Dónde se aplica? Se agrega al final de cualquier comando gcloud, como hiciste tú:

gcloud iam service-accounts create jenkins-devsecops ... --log-http



Instalación local (una vez, por desarrollador):

    pip install pre-commit
    pre-commit install





**Snyk no es multietapa**

SAST

- pre-commit: A framework for managing and maintaining multi-language pre-commit hooks.
- sonarlint (Plugin IDE) IDE-integrated SAST  /pre-commit,
- sonarcloud
- sonarqube

- gosec


SCA

- govulncheck
- OWASP Dependency-Check


SECRET SCANNING

- gitleaks
- TruffleHog: --only-verified intenta validar el secreto contra la API real del proveedor

> Si algún día te importa más la precisión que la velocidad, ahí es donde TruffleHog gana. Para agregarlo ahora, Gitleaks es la elección correcta.


IAC Scanning

- kicks
- Checkov
- CDK Nag





CONTAINER/IMAGE SCANNNING

- Trivy  https://github.com/aquasecurity/trivy   The All-in-One Security Scanner
- Grype/Anchor (son lo mismo)
- Clair

> Responsabilidad unica:

**Anchore**

Con Grype (escaneo de imagen) + Syft (SBOM) tienes:

- Los dos escritos en Go por Anchore, lo que confirma tu intuición: encajan naturalmente en un pipeline centrado en el ecosistema Go

- Syft genera el SBOM, Grype lo consume directamente para buscar vulnerabilidades — están diseñados para trabajar en tándem, exactamente el flujo "generar inventario → escanear ese inventario" que es la práctica correcta (en vez de escanear la imagen "a ciegas" cada vez).


**Aqua**

Con trivy

tu pipeline ya sigue una filosofía de una herramienta, una responsabilidad clara — Gosec solo hace SAST, govulncheck solo hace SCA, KICS solo hace IaC. Trivy rompe esa filosofía: es "una herramienta que hace de todo" (imagen, IaC, secretos, SBOM), lo cual sirve muy bien para gente que quiere consolidar y automatizar rápido, pero para ti significaría tener dos herramientas compitiendo por el mismo trabajo — KICS y Trivy ambos escaneando IaC, por ejemplo — que es justo la redundancia


RASP

- Coraza


DAST
- ZAP






OPERATE/MONITOR

- Scan container registry



https://goharbor.io/

https://github.com/goharbor/harbor





Imagenes Enfermas

- Juice Shop
- ...


Medium



Analisis de Falcos positivos


Darle un foco en Nube multiCloud


    https://gocloud.dev/  golang + CDK


Buckets

Vulnerabilidades en buckets
JDBL Video




feat: — nueva funcionalidad para el usuario/consumidor del código
fix: — corrección de un bug
ci: — cambios en configuración o scripts de CI/CD (tu Jenkinsfile)
docs: — solo documentación (README, comentarios)
refactor: — cambio de código que no agrega feature ni corrige bug (reestructurar sin cambiar comportamiento)
test: — agregar o corregir tests, sin tocar código de producción
chore: — tareas de mantenimiento que no encajan en las anteriores (actualizar dependencias, configurar .gitignore, etc.)
perf: — cambio enfocado específicamente en mejorar rendimiento
style: — formato, espacios, punto y coma — nunca lógica



git show 14e3674:terraform/terraform.tfstate


git filter-repo
