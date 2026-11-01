<div align="center">

# Advanced Tool Suite · NEXUS

**Un centro de control para Windows, en español.**

PowerShell · WPF · 42 herramientas · Plugins declarativos · Un único autoextraíble

[Inicio rápido](#inicio-rápido) · [Manual](MANUAL.md) · [Seguridad](SECURITY.md) · [Cambios](CHANGELOG.md) · [Contribuir](CONTRIBUTING.md)

**v4.0.0 · inicio de desarrollo · no certificada para producción**

</div>

> **Estado honesto:** hay código, documentación y pruebas automatizadas. Las verificaciones estáticas no certifican que WPF, los cambios administrativos o los paquetes EXE/MSI funcionen correctamente en tu equipo. Consulta los resultados reales de [CI](https://github.com/yhquintero/Advanced_Tool_Suite/actions) y la [matriz Windows](docs/PRUEBAS-WINDOWS.md). No se promete seguridad absoluta.

## Qué es y qué no es

Advanced Tool Suite organiza diagnósticos y accesos administrativos de Windows en un panel local: tarjetas redondeadas, temas, buscador, favoritos, actividad y estado del equipo. No es un antivirus, un sistema de autenticación empresarial ni un servicio de administración remota.

| Incluido en el código | Alcance |
| --- | --- |
| Panel WPF en español | 42 herramientas por categorías; cuatro temas y modo compacto |
| Diagnóstico | CPU/RAM/espacio, información, red, inventarios y salud reportada por Windows |
| Controles por acción | Confirmaciones y UAC cuando corresponde, no elevación global |
| Registro operativo | Actividad exportable, auditoría y rotación; **no inmutables** |
| Plugins v4, fase inicial | JSON de diagnósticos permitidos; sin ejecutar PS1/DLL/EXE de terceros |
| Autoextraíble | Un `.ps1` crea las fuentes y recursos completos en una carpeta nueva |
| Distribución | Recetas EXE/MSI y firma opcional; no implica paquetes compilados/firmados |

**Todavía planificado:** i18n ES/EN/PT, gráficas, editor visual de temas, AD, workflows y host aislado de código externo. [Hoja de ruta](docs/ROADMAP-v4.0.0.md).

## Inicio rápido

### Requisitos

- Windows 10/11 **x64 de escritorio**, Windows PowerShell **5.1** y .NET Framework **4.8**.
- Usuario estándar recomendado; concede UAC solo para una acción que comprendas.
- No compatible con Linux, macOS, Server Core ni PowerShell 7 como plataforma soportada.

### Opción A · un único archivo

Obtén [`Releases/AdvancedToolSuite-v4.0.0-setup.ps1`](Releases/AdvancedToolSuite-v4.0.0-setup.ps1) de una revisión que hayas verificado. Guarda el fichero y abre Windows PowerShell en esa carpeta:

```powershell
# Comprueba el contenido sin crear archivos
powershell.exe -NoProfile -File .\AdvancedToolSuite-v4.0.0-setup.ps1 -ValidateOnly

# Crea el proyecto en una carpeta NUEVA y abre el panel
powershell.exe -NoProfile -File .\AdvancedToolSuite-v4.0.0-setup.ps1 -Launch
```

Sin `-Launch` solo extrae. No descarga dependencias, no instala tareas/registro y no sobrescribe un destino existente. El fichero no está firmado aquí: sus hashes detectan incoherencias, **no autentican a quien lo distribuye**. [Instrucciones completas](LEEME-PRIMERO.md).

### Opción B · desde las fuentes

```powershell
powershell.exe -NoProfile -STA -File .\Tool\AdvancedToolSuite.ps1
```

También puedes abrir `Tool/Iniciar.cmd`. El PS1 principal contiene XAML e iconos y no requiere módulos externos para mostrar el panel. No uses el `.bat` heredado: se conserva como referencia y no incorpora las protecciones de la interfaz nueva.

Si una política bloquea el script, consulta a tu administrador. Revisa origen y contenido antes de desbloquear un archivo descargado. No desactives antivirus, SmartScreen o políticas corporativas para evitar avisos. Nunca ejecutes descargas mediante `iex` ni comandos de instalación opacos.

## Antes de realizar cambios

- Haz copia de seguridad y prueba operaciones delicadas en una VM con instantánea.
- Convertir FAT32 a NTFS no se revierte con el botón Deshacer ni con un punto de restauración.
- Apagar/reiniciar es inmediato tras confirmar. Desactivar firewall reduce la protección del equipo.
- Deshacer cubre **un solo valor interno** de Registro; no cambios externos ni operaciones generales.
- Puntos de restauración necesitan Protección del sistema y pueden estar limitados por Windows.
- Solo lectura y clave local previenen accidentes; una persona con acceso al perfil/código puede modificarlos. **No son fronteras de privilegios.**
- Cerrar el panel no cancela automáticamente herramientas externas. `DISPATCHED` significa enviado, no completado.

Más detalles en [SECURITY.md](SECURITY.md) y [MANUAL.md](MANUAL.md).

## Privacidad y registros

La suite no implementa telemetría. Ping y herramientas de Windows pueden generar tráfico cuando las solicitas. Los inventarios pueden incluir usuario, red y números de serie: revisa y anonimiza antes de compartirlos.

| Ubicación | Contenido |
| --- | --- |
| `%LOCALAPPDATA%\AdvancedToolSuite` | Preferencias, actividad, auditoría, versiones, protección local y plugins |
| `Documentos\AdvancedToolSuite\Reportes` | Inventarios manuales |
| `Documentos\AdvancedToolSuite\Programados` | Informes de tareas `ATS-Informe-*` |
| `C:\REPORTE\audit.log` | Copia adicional solo si hay permisos; no se cambian ACL |

Actividad/auditoría rotan al superar 5 MiB, con cinco copias. Los logs son editables y no garantizan cumplimiento normativo. La desinstalación conserva datos e informes deliberadamente. [Política de seguridad y exposición de datos](SECURITY.md).

## Instalación, compilación y firma

`install.ps1` y `uninstall.ps1` funcionan sobre una distribución Portable/Exe **generada**, no sobre el repositorio sin construir. Instalan por usuario con recibo, hashes y `-WhatIf`. No mezcles MSI y scripts en el mismo destino.

```powershell
.\packaging\Build-Release.ps1 -Format Portable
# EXE: ps2exe revisado + mt.exe del SDK; MSI: además WiX
.\packaging\Build-Release.ps1 -Format Exe
```

[BUILD.md](BUILD.md) explica requisitos, manifiesto `asInvoker`, Authenticode, sello de tiempo y límites. No se incluyen certificados privados ni se afirma que existan binarios firmados publicados.

## Pruebas y calidad

```sh
python packaging/Build-Bootstrap.py
python -m unittest discover -s tests -v
```

En Windows PowerShell 5.1:

```powershell
.\tests\Validar-PowerShell.ps1
.\tests\Probar-Contratos.ps1
.\tests\Probar-Plugins.ps1
.\tests\Run-Pester.ps1
powershell.exe -NoProfile -STA -File .\Tool\AdvancedToolSuite.ps1 -SmokeTest
```

La suite Pester define 43 casos y su runner exige 43/43. Eso no significa que hayan pasado en todas las máquinas o revisiones. CI usa permisos mínimos y acciones fijadas por SHA; consulta sus resultados, no solo una insignia. [Validaciones y límites](docs/REVISION-4.0.0.md).

## Documentación y web

- [Primera ejecución](LEEME-PRIMERO.md) · [Manual](MANUAL.md) · [Construcción](BUILD.md)
- [Plugins](Plugins/README.md) · [Versiones](CHANGELOG.md) · [Roadmap](docs/ROADMAP-v4.0.0.md)
- [Contribuciones](CONTRIBUTING.md) · [Seguridad](SECURITY.md) · [Licencias de terceros](THIRD_PARTY_NOTICES.md)
- [Web estática y configuración GitHub pendiente](docs/SEGURIDAD-REPOSITORIO.md)
- [Revisión del rediseño web y mantenimiento del catálogo](docs/REVISION-WEB.md)

La web de presentación está en `site/`, con portada, catálogo desplegable de las 42 herramientas en 6 categorías, guía local y página de seguridad. Ofrece temas claro/oscuro según el sistema y no contiene JavaScript, formularios, cookies, analítica ni recursos remotos. Su publicación en GitHub Pages requiere habilitación y despliegue; no se anuncia como activa sin comprobarlo. El enlace Website del About propuesto apunta al README mientras tanto.

## Licencia

[MIT](LICENSE), con [traducción informativa al español](LICENSE.es.md). El texto canónico facilita su identificación por GitHub. Los mantenedores deben confirmar derechos y atribuciones de contribuciones heredadas antes de distribuir. MIT no relicencia componentes de Microsoft ni dependencias externas y no ofrece garantía de seguridad.

## Colaborar o reportar problemas

Para fallos normales usa [Issues](https://github.com/yhquintero/Advanced_Tool_Suite/issues) y las plantillas, sin datos sensibles. **No publiques vulnerabilidades explotables, claves, contraseñas ni inventarios completos**: sigue [SECURITY.md](SECURITY.md). Las PR deben incluir pruebas, documentación y regeneración del autoextraíble cuando cambian sus fuentes.
