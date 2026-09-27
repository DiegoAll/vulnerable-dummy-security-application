# vulnerable-dummy-security-application

Vulnerable dummy security application


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
