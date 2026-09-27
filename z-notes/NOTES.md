



2. ¿Cómo automatizar la ejecución tras un git push (Webhook / SCM Polling)?En GitHub Actions la infraestructura la gestiona GitHub, por lo que detecta el evento push internamente. En Jenkins (que corre en local o servidor propio), hay dos alternativas principales para lograr esto:Opción A: GitHub Webhook (Recomendada en Servidores Públicos / Ngrok)GitHub le envía una notificación HTTP (Webhook) a Jenkins cada vez que alguien hace push o merge de un PR.Configurar Jenkins:En la configuración de tu Job en Jenkins, ve a la sección Triggers (Disparadores).Marca la casilla GitHub hook trigger for GITScm polling.   Guarda los cambios.Configurar GitHub:En tu repositorio de GitHub (DiegoAll/vulnerable-dummy-security-application), ve a Settings > Webhooks > Add webhook.Payload URL: http://<TU_IP_O_DOMINIO_PUBLICO>:8081/github-webhook/ (Si usas localhost, necesitas exponer el puerto con una herramienta como ngrok http 8081).Content type: application/json.Selecciona el evento Just the push event y guarda.Opción B: SCM Polling / Poll SCM (Ideal para entorno de desarrollo Local)Jenkins consulta periódicamente a GitHub para verificar si hay nuevos commits. Si detecta un cambio nuevo en la rama main, ejecuta el pipeline automáticamente.En la configuración de tu Job en Jenkins (http://localhost:8081/job/vulnerable-dummy-security-application/configure), desplázate a la sección Triggers.   Marca la opción Consultar repositorio (SCM) (en inglés Poll SCM).   En el campo Schedule, puedes programar la frecuencia usando sintaxis tipo cron:H/2 * * * * (Consulta a GitHub cada 2 minutos).H/5 * * * * (Consulta a GitHub cada 5 minutos).Haz clic en Save.   Con cualquiera de las dos opciones activadas, el pipeline se disparará automáticamente sin necesidad de oprimir manualmente el botón Construir ahora.



Sobre --skip-ci: en realidad no es un flag literal de git merge — me expresé mal antes. Lo que existe es una convención de mensaje de commit que los sistemas de CI reconocen para no disparar el pipeline en absoluto (no es "romper el build", es evitar que corra):

GitHub Actions / GitLab CI: git commit -m "fix: typo [skip ci]" o [ci skip]
Jenkins con el plugin correspondiente reconoce el mismo patrón si está configurado



1. ¿Por qué las Unit Tests se ejecutan ANTES del Build del Artefacto?
Ejecutar las pruebas unitarias antes de la compilación sigue el principio fundamental de Fail-Fast (Fallo Rápido) en la Integración Continua (CI):

- Ahorro de recursos y tiempo: Compilar una aplicación, construir una imagen de Docker o empaquetar un artefacto requiere tiempo y cómputo. Si la lógica de tu código no pasa las pruebas unitarias básicas, no tiene sentido perder recursos compilando un binario defectuoso.

- Garantía de calidad en la construcción: Asegura que solo el código verificado funcionalmente genere artefactos. Si inviertes el orden, estarías generando binarios "listos para producción" que en realidad contienen errores lógicos o rompen funcionalidades existentes.

- Flujo de promoción limpio: En CI/CD, el artefacto compilado debe ser el producto final de un código 100% probado.




Sí — el problema es que go test no genera un reporte estructurado, solo texto plano. Para que Jenkins lo pueda graficar (tendencias, historial de pass/fail, tiempos por test) necesitas convertirlo a JUnit XML, que es el formato que Jenkins entiende nativamente.


Para convertir la salida de Go a JUnit XML, la herramienta estándar es gotestsum (más completa que go-junit-report, también da un resumen más legible en consola):


https://gotestsum.com/

https://trunk.io/testing/gotestsum


https://github.com/gotestyourself/gotestsum



2. Ver los archivos de Profiling (cpu.pprof y mem.pprof)
Los archivos .pprof son datos binarios comprimidos de rendimiento, por lo que no se pueden ver directamente en formato de texto o HTML nativo en el navegador; están diseñados para ser analizados con la herramienta oficial de Go.

Para analizarlos de forma interactiva en tu navegador (con gráficos de llamadas y consumo de memoria):


sast (Go Sec)
gosec - Go Security Checker

https://github.com/securego/gosec


https://github.com/securego/gosec/blob/master/RULES.md






¿Por qué esto sigue siendo solo CI?
Integración Continua (CI): Se encarga de validar, analizar y verificar la calidad y seguridad del código fuente antes de desplegarlo. Abarca:

Compilación: Verificar que el código construya correctamente.

Pruebas Unitarias y Cobertura: Validar funcionalidad y lógica.

SAST (Gosec): Análisis estático para detectar fallas de seguridad en el código propio.

SCA (Govulncheck): Análisis de componentes/dependencias vulnerables.

Artefacto: Generar el binario compilado listo para ser tomado por otra etapa.

Entrega/Despliegue Continuo (CD): Inicia después del CI y se encarga del aprovisionamiento de infraestructura y despliegue del binario/contenedor en entornos de staging o producción (por ejemplo, Kubernetes, AWS, GCP o SSH a un servidor web). Como tu pipeline actualmente termina en la fase Build Artifact, aún no realiza CD.


No, DAST por definición pertenece al ámbito de CD o a un entorno post-despliegue.



Opción Recomendada: Kubernetes en GKE
Simulación Realista de Microservicios: Permite desplegar el pod de la API Go junto a un pod de base de datos PostgreSQL dentro de un namespace aislado.

Escenarios de Seguridad Avanzados: Adicional a las vulnerabilidades en código (SQLi), permite evaluar e implementar controles de infraestructura como:

Reglas de NetworkPolicy para mitigar movimiento lateral.

Configuración de SecurityContext (evitar ejecución como root).

Reglas en KICS para validar configuraciones de Kubernetes (YAMLs).

Frontend Integrado: Facilita la adición posterior del frontend en React desplegándolo como otro Pod o servicio expuesto dentro del mismo cluster.


🏗️ Ejecutando KICS para escaneo de IaC (Dockerfile/K8s)...
[Pipeline] sh
+ pwd
+ docker run --rm -v /var/jenkins_home/workspace/vulnerable-dummy-security-application:/path checkmarx/kics:latest scan -p /path -o /path --output-name kics-report --report-formats json,txt
docker: Error response from daemon: error while creating mount source path '/var/jenkins_home/workspace/vulnerable-dummy-security-application': mkdir /var/jenkins_home: read-only file system


El demonio de Docker (fuera del contenedor) intenta acceder a la ruta física /var/jenkins_home/..., la cual es de solo lectura o difiere entre el host y el contenedor de Jenkins.

Solución:
En el paso de KICS, debes indicarle a Docker que use el directorio /tmp interno del contenedor o ajustar los permisos de montaje usando la variable de entorno de Jenkins ($WORKSPACE o $(pwd)):



Diagnóstico Técnico del Error
Este problema ocurre por la arquitectura de Docker-in-Docker (DinD) o el mapeo del socket /var/run/docker.sock en Jenkins:


[DIND]

El demonio de Docker corre directamente en el Host (tu máquina), mientras que Jenkins ejecuta dentro de un contenedor.

Cuando el script de Jenkins envía la orden docker run -v "${WORKSPACE}":/path, Jenkins pasa la ruta interna del contenedor (/var/jenkins_home/...).

El demonio de Docker en el Host no conoce esa ruta interna y trata de crear el directorio /var/jenkins_home en el sistema de archivos del Host, fallando con read-only file system.

Al fallar el montaje, KICS no escaneó nada y por eso Jenkins reporta 'kics-report.*' doesn't match anything.


Solución en Jenkinsfile
En entornos Jenkins donde la variable ${WORKSPACE} interna difiere del sistema de archivos host, se debe usar un directorio de trabajo seguro o la ruta relativa ($(pwd) referenciando el volumen compartido), o bien pasar la variable de entorno que mapea la ruta host.

La solución más limpia e idónea para KICS en este tipo de agentes Jenkins consiste en usar el volumen nombrado o mapear el directorio utilizando la variable local de trabajo:


Sí, hay varias opciones sin necesidad de DefectDojo ni de instalar plugins nuevos en Jenkins. Dado que ya tienes una instancia local de SonarQube corriendo en tu laboratorio de DevSecOps (con sonar-token configurado en Jenkins), la opción que mejor encaja es esta:

1. Importar los hallazgos a SonarQube usando el formato nativo que KICS ya soporta

Te diste cuenta en la lista de --report-formats de KICS que existe la opción sonarqube. Eso no es casualidad: KICS puede generar un reporte en el formato "Generic Issue Import" que SonarQube entiende de forma nativa, sin plugin adicional en Jenkins ni en SonarQube — solo se lo pasas al scanner.




RASP

https://github.com/corazawaf/coraza

Opción A — RASP real embebido como librería (la más práctica para tu app de Go)

Coraza (github.com/corazawaf/coraza) es un WAF/RASP compatible con las reglas OWASP Core Rule Set (CRS), escrito en Go puro, pensado exactamente para embeberse como middleware en un router como chi (el que ya usas). En tiempo de ejecución inspecciona cada request/response contra las reglas CRS y puede bloquear intentos de SQLi, XSS, path traversal, etc., antes de que lleguen a tu HealthHandler. A diferencia de KICS o Gosec, esto no genera un reporte en Jenkins — protege la app mientras corre.

Implementación a alto nivel en tu main.go:

Agregar github.com/corazawaf/coraza/v3 a go.mod.
Cargar el conjunto de reglas OWASP CRS (se descargan como archivos de configuración, similar a como bajaste los assets de KICS).
Envolver tus rutas de chi con un middleware que pase cada request por el motor de Coraza antes del handler real.


3. Escaneo de secretos (Secrets Scanning) explícito — KICS ya hace una pasada de detección de secretos por defecto (por eso existe el flag --disable-secrets), pero es limitada. Si quieres algo más robusto y con historial de git completo, se agrega Gitleaks o TruffleHog como stage aparte.



4. Image Scanning — ¿CI, CD (delivery) o CD (deployment)?

Está justo en la frontera, y depende de qué tan estricta sea tu definición:

La imagen se construye típicamente al final de CI (tu stage Build Artifact, si lo extendieras a docker build).
Escanearla antes de subirla a un registry o promoverla es la práctica estándar, y eso cae en Continuous Delivery — es el gate de calidad/seguridad que decide si el artefacto está listo para entregarse.
Si además vuelves a escanear la imagen ya en el registry de forma periódica (porque aparecen CVEs nuevas para paquetes que ya estaban ahí, aunque el código no cambió), eso ya es una actividad continua post-delivery, más cercana a "Operate/Monitor" que a CI o CD propiamente.


En la práctica, la mayoría de equipos simplemente lo mete como el último gate de CI antes de hacer docker push, así que verás bibliografía que lo cataloga como CI y otra que lo cataloga como CD — ambas son defendibles, pero conceptualmente pertenece más a CD (es un gate de "¿este artefacto es apto para entregarse?", no de "¿este código compila y pasa tests?").

5. Mejor opción para Container Scanning: Trivy, Grype o Anchore

Mi recomendación para tu laboratorio: Trivy. Razones concretas para tu caso:

Es un binario único (igual que hiciste con KICS), fácil de descargar y correr en Jenkins sin infraestructura adicional — a diferencia de Anchore Engine, que necesita su propio servicio + base de datos corriendo.
Cubre más terreno con la misma herramienta: escaneo de imagen (SO + dependencias de la app), IaC, secretos y SBOM. Podrías incluso, en teoría, reemplazar tu stage de KICS por Trivy si algún día quieres consolidar herramientas — aunque yo dejaría KICS como está porque ya te costó dejarlo funcionando y tiene mejor cobertura específica de reglas de Kubernetes.
Mantenimiento activo por Aqua Security, actualizaciones de base de datos de vulnerabilidades muy frecuentes.

Grype es una alternativa perfectamente válida y algo más rápida si solo te interesa vulnerabilidades de imagen (sin IaC ni secretos) — es más "hace una cosa bien" en vez de "hace varias cosas razonablemente bien" como Trivy. No hay una respuesta objetivamente incorrecta entre las dos; para un pipeline que ya tienes fragmentado en stages específicos (SAST separado, SCA separado, IaC separado), Grype encajaría más limpio filosóficamente (una herramienta, un propósito). Para minimizar el número de binarios distintos que mantienes, Trivy gana.

No conozco ninguna alternativa open source que supere claramente a estas dos para este caso de uso — son el estándar de facto hoy en día.

6. Falco — ¿sirve como RASP?

No, y la diferencia es importante: Falco es Runtime Threat Detection / seguridad runtime de contenedores (categoría CWPP — Cloud Workload Protection Platform), no RASP.

La diferencia de fondo:

Falco vive fuera de tu aplicación, a nivel de kernel (usando eBPF), y observa syscalls del sistema operativo: detecta cosas como "se abrió una shell dentro de un contenedor", "se escribió en /etc/shadow", "un proceso hizo una conexión de red saliente inesperada". No entiende nada de tu lógica de negocio ni de HTTP — es agnóstico a la aplicación.
RASP vive dentro del proceso de tu aplicación (como Coraza que te mencioné antes), entiende el contexto de la petición HTTP, el body, los parámetros, y puede bloquear un intento de SQLi o XSS antes de que tu código de negocio lo procese.

En términos prácticos: Falco te avisa después de que algo ya comprometió el contenedor (señales de post-explotación), mientras que RASP intenta evitar que la explotación ocurra en primer lugar a nivel de aplicación. No son sustitutos, son complementarios en una estrategia de defensa en profundidad — de hecho, tiene mucho sentido tener ambos: Coraza como RASP en tu app Go, y Falco corriendo en el clúster de Kubernetes como red de seguridad si algo se escapa igual. Como ya tienes Falco instalado en Kubernetes, no lo quites — solo no esperes que cumpla el rol de RASP, son capas distintas de la misma estrategia.



TruffleHog tiene una ventaja real que vale la pena mencionar: su modo --only-verified intenta validar el secreto contra la API real del proveedor (por ejemplo, verifica si una API key de AWS encontrada todavía está activa), lo que reduce muchísimo el ruido de secretos ya rotados o de ejemplos de documentación. Es más pesado y más lento, y depende de hacer llamadas salientes a internet desde tu Jenkins — probablemente no lo quieres en un lab local. Si algún día te importa más la precisión que la velocidad, ahí es donde TruffleHog gana. Para agregarlo ahora, Gitleaks es la elección correcta.



Trivy vs Grype+Anchore — la pregunta filosófica

Tu instinto de leer esto como una decisión de arquitectura, no solo "cuál herramienta es mejor", es el correcto. Aquí está mi recomendación y el porqué, pensando en tu ecosistema Go y en que ya tienes stages bien separados por responsabilidad (SAST separado, SCA separado, IaC separado):

Ve por la línea Grype + Syft, no por Trivy, y esta es la razón de fondo: tu pipeline ya sigue una filosofía de una herramienta, una responsabilidad clara — Gosec solo hace SAST, govulncheck solo hace SCA, KICS solo hace IaC. Trivy rompe esa filosofía: es "una herramienta que hace de todo" (imagen, IaC, secretos, SBOM), lo cual sirve muy bien para gente que quiere consolidar y automatizar rápido, pero para ti significaría tener dos herramientas compitiendo por el mismo trabajo — KICS y Trivy ambos escaneando IaC, por ejemplo — que es justo la redundancia que dijiste que quieres evitar al ser tan explícito sobre "IaC es vital".

Con Grype (escaneo de imagen) + Syft (SBOM) tienes:

Cada binario con una responsabilidad única, igual que el resto de tu pipeline.
Los dos escritos en Go por Anchore, lo que confirma tu intuición: encajan naturalmente en un pipeline centrado en el ecosistema Go, y probablemente los podrías incluso importar como librería Go si algún día quieres construir tooling propio en vez de solo invocar el binario por CLI.
Syft genera el SBOM, Grype lo consume directamente para buscar vulnerabilidades — están diseñados para trabajar en tándem, exactamente el flujo "generar inventario → escanear ese inventario" que es la práctica correcta (en vez de escanear la imagen "a ciegas" cada vez).

Sobre Anchore Engine (el servicio completo, no Grype/Syft): descártalo para tu lab. Requiere levantar su propio servicio + base de datos Postgres — es exactamente el tipo de infraestructura pesada que evitaste con KICS al usar binario nativo en vez de contenedor. No aporta nada que Grype no te dé ya, para tu escala actual.

Syft para SBOM — sí, agrégalo, y aquí está el porqué estratégico

No es solo "una herramienta más" — el SBOM es lo que conecta todo lo que ya construiste:

Con Syft generas el inventario de dependencias de tu imagen (paquetes del SO + módulos Go).
Con Grype escaneas ese SBOM contra bases de CVE actualizadas — más rápido que reescanear la imagen completa cada vez, porque puedes cachear el SBOM y solo reescanearlo cuando cambian las CVEs conocidas, no cuando cambia la imagen.
Te da trazabilidad real: si mañana aparece una CVE crítica en una librería, puedes buscar en tus SBOMs históricos exactamente en qué builds estaba presente, sin tener que re-analizar cada imagen vieja.

Orden lógico de stages nuevos (después de tu Build Artifact, ya que necesitas la imagen construida):

Build Artifact
  → Build Docker Image (nuevo, si aún no construyes la imagen en el pipeline)
  → Security - SBOM (Syft)          # genera el inventario
  → Security - Container Scan (Grype)  # escanea ese inventario





Sobre el IMAGE_TAG_PLACEHOLDER: no puedes hardcodear el tag de build en un manifiesto que vive commiteado en git, porque cambia en cada ejecución de Jenkins (${BUILD_NUMBER}). La forma estándar de resolver esto sin meter herramientas nuevas (Kustomize, Helm) es sustituir el placeholder con sed justo antes del kubectl apply, en el propio stage de Jenkins — te muestro esto abajo.
