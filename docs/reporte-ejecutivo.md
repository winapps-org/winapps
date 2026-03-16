# Reporte Ejecutivo: Como Funciona el Sistema WinApps

## Resumen ejecutivo
WinApps permite ejecutar aplicaciones de Windows desde GNU/Linux con una experiencia integrada al escritorio. En lugar de emular cada aplicacion individualmente, el sistema levanta una instancia real de Windows en una maquina virtual o contenedor, detecta las aplicaciones instaladas y publica accesos directos en Linux para abrirlas mediante sesiones RDP tipo RemoteApp.

El resultado operativo es que el usuario puede lanzar Word, Excel, Adobe u otras aplicaciones de Windows desde el menu de aplicaciones de Linux, abrir archivos asociados y compartir su carpeta home con el entorno Windows, sin salir de su escritorio habitual.

## Objetivo del sistema
- Ejecutar aplicaciones nativas de Windows sobre Linux con una capa de integracion de escritorio.
- Evitar configuraciones manuales por aplicacion, centralizando el acceso a traves de una unica VM o contenedor Windows.
- Reutilizar componentes estables del ecosistema: Windows, RDP, FreeRDP, Docker, Podman o libvirt.

## Como funciona a alto nivel
El sistema sigue este flujo:

1. WinApps ejecuta Windows usando uno de tres backends: Docker, Podman o libvirt.
2. El instalador valida dependencias, carga la configuracion del usuario y verifica conectividad RDP.
3. Windows es consultado para detectar aplicaciones instaladas y sus ejecutables.
4. WinApps genera iconos, metadatos y archivos .desktop en Linux.
5. Cuando el usuario abre una aplicacion, WinApps invoca FreeRDP y publica la app de Windows como si fuera una ventana local.

## Arquitectura funcional
### 1. Capa de ejecucion Windows
WinApps no ejecuta binarios Windows directamente en Linux. La aplicacion corre dentro de una instancia de Windows que puede vivir en:

- Docker o Podman, usando la plantilla compose.yaml para automatizar despliegue y ciclo de vida.
- libvirt, para entornos con mayor control, personalizacion o passthrough de hardware.

En todos los casos, Windows expone RDP por el puerto 3389 y se convierte en el runtime real de las aplicaciones.

### 2. Capa de orquestacion en Linux
Los scripts principales del proyecto coordinan el sistema:

- setup.sh instala WinApps, valida dependencias, prueba la conexion RDP, detecta aplicaciones y genera integracion con el escritorio.
- bin/winapps actua como lanzador operativo: arranca, pausa o conecta contra Windows y abre sesiones RDP completas o aplicaciones individuales.
- install/ExtractPrograms.ps1 corre del lado Windows para descubrir aplicaciones, rutas de ejecutables e iconos.

### 3. Capa de integracion de escritorio
Una vez detectadas las aplicaciones, WinApps genera:

- archivos .desktop para cada aplicacion soportada o descubierta;
- iconos locales en Linux;
- asociaciones MIME para abrir documentos con apps Windows;
- un handler de protocolos Microsoft Office para enlaces como ms-word://.

## Flujo operativo detallado
### Fase 1. Configuracion
El usuario define un archivo de configuracion en ~/.config/winapps/winapps.conf con variables como:

- credenciales RDP;
- IP o nombre de la VM;
- backend seleccionado en WAFLAVOR;
- flags adicionales para FreeRDP;
- escala grafica y tiempos de espera.

Este archivo es el punto central de control del sistema.

### Fase 2. Validacion tecnica
Antes de instalar o ejecutar, WinApps verifica:

- que existan dependencias como git, curl, dialog, netcat y FreeRDP v3;
- que la configuracion sea valida;
- que Windows sea alcanzable por red;
- que el puerto RDP este abierto.

Esto reduce fallas de integracion antes de exponer accesos al usuario final.

### Fase 3. Descubrimiento de aplicaciones
WinApps identifica aplicaciones de dos maneras:

- aplicaciones oficialmente soportadas definidas en la carpeta apps, con nombre, ejecutable, icono y MIME preconfigurados;
- aplicaciones detectadas dinamicamente desde Windows mediante PowerShell.

El script ExtractPrograms.ps1 inspecciona varias fuentes en Windows, entre ellas:

- Windows Registry;
- aplicaciones UWP;
- shims de Chocolatey;
- ejecutables instalados que puedan publicarse por RDP.

Ademas, extrae iconos desde los ejecutables y los serializa en base64 para reconstruirlos en Linux.

### Fase 4. Publicacion en Linux
Con esa informacion, setup.sh crea la integracion local:

- guarda iconos en ~/.local/share/winapps o en la ruta del sistema;
- genera archivos .desktop con comandos del tipo winapps <app> %F;
- registra MIME types para abrir archivos desde Nautilus u otros entornos compatibles;
- agrega un acceso para una sesion completa de Windows.

Desde la perspectiva del usuario, las aplicaciones quedan visibles como si fueran aplicaciones nativas del menu del sistema.

### Fase 5. Ejecucion de aplicaciones
Cuando el usuario abre una aplicacion:

1. Se ejecuta el comando winapps correspondiente.
2. WinApps comprueba el backend y el estado de Windows.
3. Si hace falta, inicia o reanuda la VM o contenedor.
4. Abre una sesion con FreeRDP usando RemoteApp o una sesion completa de escritorio.
5. La ventana de la aplicacion aparece integrada en Linux.

El binario sigue ejecutandose en Windows, pero su presentacion y lanzamiento quedan integrados en el entorno Linux.

## Componentes clave del sistema
### FreeRDP
Es el motor de presentacion remota. WinApps depende de FreeRDP v3 para:

- autenticar la sesion RDP;
- renderizar la ventana de la aplicacion;
- montar la carpeta home del usuario dentro de Windows;
- aplicar opciones como escala, sonido o multimonitor.

### Windows como subsistema de aplicaciones
Windows actua como un subsistema de compatibilidad real. Esto permite alta compatibilidad con software empresarial y comercial, incluyendo Microsoft 365 y Adobe Creative Cloud.

### Definiciones de apps
La carpeta apps contiene definiciones curadas para aplicaciones probadas por la comunidad. Estas definiciones mejoran:

- nombre visible;
- iconografia;
- asociaciones MIME;
- ruta del ejecutable.

### Launcher opcional
El proyecto tambien contempla WinApps Launcher como complemento para administrar la VM o contenedor y lanzar aplicaciones desde una bandeja del sistema.

## Modos de operacion soportados
### Docker o Podman
Es la via recomendada para la mayoria de usuarios porque simplifica despliegue, recreacion y operacion continua de Windows.

### libvirt
Es la via recomendada para usuarios avanzados que necesitan:

- mayor control del hardware virtual;
- optimizacion manual de la VM;
- escenarios avanzados como GPU passthrough.

## Fortalezas del sistema
- Alta compatibilidad con aplicaciones Windows reales.
- Integracion directa con el escritorio Linux.
- Capacidad de abrir archivos asociados desde el explorador.
- Arquitectura modular basada en componentes conocidos.
- Soporte para aplicaciones curadas y deteccion automatica.

## Limitaciones y consideraciones
- Requiere una instalacion funcional de Windows con RDP habilitado.
- Depende de virtualizacion y, por tanto, de CPU, RAM y configuracion del host.
- Windows Home no es suficiente para escenarios RDP publicados.
- La experiencia final depende de red local, latencia, FreeRDP y configuracion del backend.
- No reemplaza compatibilidad a nivel kernel, por lo que ciertos casos especiales siguen fuera de alcance.

## Conclusiones
WinApps no es solo un lanzador de aplicaciones: es una capa de integracion entre Linux y una instancia Windows remota o virtualizada. Su valor esta en transformar aplicaciones Windows en recursos accesibles desde el escritorio Linux mediante automatizacion de despliegue, descubrimiento de software, generacion de accesos y publicacion por RDP.

Desde una vision ejecutiva, el sistema resuelve un problema concreto de compatibilidad sin exigir que el usuario abandone Linux como entorno principal. La arquitectura prioriza compatibilidad, reutilizacion de tecnologias maduras y una experiencia de uso cercana a la de una aplicacion nativa.