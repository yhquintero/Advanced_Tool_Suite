> **Entrega en un solo fichero:** usa [`Releases/AdvancedToolSuite-v4.0.0-setup.ps1`](Releases/AdvancedToolSuite-v4.0.0-setup.ps1). Crea el árbol completo sin descargas ni sobrescritura. Instrucciones en [LEEME-PRIMERO.md](LEEME-PRIMERO.md).

# Advanced Tool Suite · NEXUS 4.0.0 · inicio de desarrollo

Centro de control **en español** para Windows 10/11, con interfaz PowerShell/WPF, colores futuristas, tarjetas e iconos vectoriales y botones de bordes redondeados. **42 herramientas**, sin módulos externos para abrir el panel.

> Estado: código implementado y comprobaciones estáticas realizadas. Este entorno Linux no ejecuta WPF ni genera instaladores Windows. Las pruebas en Windows, EXE y MSI **no se dan por completadas**. Consulta la [revisión detallada](docs/REVISION-3.0.md).

## Iniciar

Requisitos: **Windows 10/11 x64 de escritorio, Windows PowerShell 5.1 y .NET Framework 4.8**. No compatible con Linux, macOS o Server Core. Utiliza Windows PowerShell, no PowerShell 7, para la versión soportada y la compilación.

Abre `Tool/Iniciar.cmd`, o desde la raíz del repositorio:

```powershell
powershell.exe -NoProfile -STA -File .\Tool\AdvancedToolSuite.ps1
```

El archivo `Tool/AdvancedToolSuite.ps1` es **autónomo**: contiene XAML e iconos, no necesita que copies `Assets`. No requiere conexión para abrirse. Ping y las herramientas de Windows que utilizan Internet sí pueden generar tráfico. La suite no implementa telemetría.

Si Windows bloquea el archivo descargado, revísalo y, solo si confías en él, usa `Unblock-File .\Tool\AdvancedToolSuite.ps1`. Si la política no permite scripts, puedes autorizar scripts locales **solo para la sesión actual** con `Set-ExecutionPolicy -Scope Process RemoteSigned` y ejecutar `& .\Tool\AdvancedToolSuite.ps1` desde esa misma sesión de Windows PowerShell en STA. No se omiten las políticas corporativas ni se modifica la política del equipo.

**No ejecutes el `.bat` antiguo para usar la nueva versión.** Se conserva sin cambios como referencia y mantiene sus riesgos originales. Inicia el panel como usuario estándar: UAC se pide por acción.

## Las 20 mejoras

El [CHANGELOG](CHANGELOG.md) describe cada punto en el orden solicitado. Resumen:

| Nº | Función | Uso / alcance |
| --- | --- | --- |
| 1–5 | Animaciones, SVG, cuatro temas, compacto y gradiente | **Ajustes**; movimiento desactivable y respetuoso de la configuración del sistema |
| 6 | Búsqueda inmediata | Combina texto, categoría y favoritos |
| 7 | Favoritos | Estrella en cada tarjeta y botón **Favoritos** |
| 8 | Historial exportable | **Exportar log**, incluye archivos rotados disponibles |
| 9 | Programación GUI | **Programar**: informe del sistema único, fecha futura y sesión iniciada |
| 10 | Verificaciones | Ejecutables, componentes, unidad, FAT32, espacio y tipo de disco identificable |
| 11 | Monitor | CPU, RAM y espacio libre del disco del sistema cada 3 s; muestra indisponibilidad si falla |
| 12 | Deshacer Registro | Un nivel: archivos ocultos, tema de aplicaciones y menú clásico/moderno |
| 13 | Auditoría | Copia local y `C:\REPORTE\audit.log` si hay permisos; sin cambiar ACL |
| 14 | Solo lectura | Ajustes; permite únicamente diagnósticos de lista blanca |
| 15 | Clave local | Ajustes; protección de acciones marcadas críticas, no sustituye permisos Windows |
| 16 | Punto de restauración | Manual o exigido antes de cambios compatibles; si falla, el cambio no sigue |
| 17 | EXE | Receta ps2exe, sin consola principal; **binario aún no compilado** |
| 18 | MSI | Receta WiX, por usuario, con icono; **instalador aún no compilado** |
| 19 | Portable | Un único `.ps1` con recursos embebidos |
| 20 | Explorador | Ajustes → instalar/retirar entrada de clic derecho del fondo de carpetas |

En modo compacto, usa el selector de categoría sobre los botones de acceso rápido. **Ajustes** siempre permite volver al tamaño completo. Las preferencias y favoritos se guardan por usuario.

La programación está intencionadamente limitada a **informes de sistema**, sin comandos libres ni contraseñas de Windows. Las tareas se llaman `ATS-Informe-*`; puedes consultar su historial o eliminarlas desde el Programador de tareas de Windows (`taskschd.msc`). No se ejecutan como SYSTEM ni con privilegios elevados. Si la sesión no está iniciada a la hora prevista, su ejecución depende de las reglas de disponibilidad del Programador.

## Seguridad y límites

- **Solo lectura es una restricción de la interfaz, no una barrera de seguridad.** Permite información del sistema, CHKDSK de lectura, memoria, salud de discos, configuración IP, ping e informes. Exportar diagnósticos escribe archivos locales. Un usuario con acceso al código/configuración puede cambiar el modo; usa cuentas limitadas y políticas de Windows si necesitas restricciones reales.
- La clave usa **PBKDF2-HMAC-SHA256 (310 000 iteraciones), sal aleatoria y DPAPI CurrentUser**. Cinco fallos bloquean durante cinco minutos. No se registra la clave. Protege contra accidentes, no contra el propio usuario, administradores o código ejecutado bajo la misma cuenta. Borrar el archivo local reinicia esta protección; no es autenticación empresarial.
- **Deshacer** restaura el último valor interno, no una imagen del Registro ni modificaciones hechas desde Regedit. Si detecta un cambio posterior ajeno, se niega a sobrescribirlo. Se pueden conservar claves padre vacías creadas por el ajuste.
- El punto previo opcional cubre cambios internos de Registro, conversión, Winsock y firewall; también deshacer. No puede interceptar cambios hechos dentro de consolas externas. Requiere Protección del sistema activada y espacio suficiente; Windows puede limitarlo a uno cada 24 horas. No se desactiva ese límite. Un punto no sustituye una copia de archivos ni revierte una conversión NTFS.
- Convertir FAT32 a NTFS requiere dos confirmaciones y una unidad FAT32. Haz copia primero; no se formatea ni se promete reversibilidad.
- Desactivar firewall deja el equipo expuesto. Winsock puede afectar conexiones y necesita reinicio.
- Apagar/reiniciar pide confirmación y después es inmediato, sin `/f`. **Cancelar apagado** solo cancela cuentas atrás ya pendientes en Windows, no ese apagado inmediato.
- La salud de discos no garantiza ausencia de fallos. El tipo de medio puede ser desconocido en RAID, volúmenes virtuales o números de serie no disponibles. No se deduce SSD por su nombre.
- Defender puede no estar disponible con otro antivirus; los ajustes del menú de Windows 11 pueden cambiar según la compilación.
- Las operaciones largas se ejecutan en consolas independientes y muestran allí su resultado. El panel monitoriza la salida del proceso hasta cerrar esa consola; si cierras la suite antes, no monitoriza su finalización ni cancela el proceso.

## Historial, versiones y auditoría

En `%LOCALAPPDATA%\AdvancedToolSuite`:

| Archivo | Contenido |
| --- | --- |
| `actividad.log` | Actividad legible, fecha/hora local y estado |
| `audit.jsonl` | Evento JSON por línea: UTC, versión, sesión, usuario, equipo, acción, estado y mensaje |
| `versiones.log` | Versiones utilizadas y resumen de mejoras, una entrada por versión |
| `preferencias.json` | Tema, animaciones, compacto, modo de lectura, restauración y favoritos |
| `registro-undo.clixml` | Último valor interno de Registro para deshacer |
| `proteccion.dpapi` | Registro cifrado con sal/hash de la clave y bloqueo temporal |

La auditoría también intenta escribir en **`C:\REPORTE\audit.log`**, sin elevar el panel ni cambiar permisos. Si no es posible, aparece una advertencia y continúa la copia local. No se considera fallo de una herramienta que falte esa copia secundaria.

Los registros de actividad y auditoría rotan cuando superan **5 MiB**, con **cinco copias** (`.1` a `.5`). La actividad visible se limita a unos 64 000 caracteres. El evento que cruza el límite puede exceder ligeramente el tamaño; la rotación se realiza en la siguiente escritura. La retención es por archivo, no por días.

Estados: `REQUEST`, `CANCELLED`, `ERROR`, `DISPATCHED`, `REGISTRY_OK`, `PROCESS_EXIT_OK/ERROR`, `RESTORE_START/OK/ERROR`, `TASK_REGISTERED`, entre otros. **DISPATCHED no significa completado**. Las aplicaciones externas no ofrecen siempre resultado consultable; una consola cerrada externamente tampoco certifica éxito. Si falla toda escritura local, la interfaz lo advierte, pero no puede garantizar una auditoría completa.

Son registros operativos **editables**, no una auditoría inmutable, firmada ni apta por sí sola para cumplimiento normativo. No cambian ACL existentes. Evita un `C:\REPORTE` compartido con permisos inseguros y revisa datos sensibles antes de exportar.

Los inventarios manuales van a `Documentos\AdvancedToolSuite\Reportes`; los programados a `Documentos\AdvancedToolSuite\Programados`. Pueden contener usuario, red y números de serie. No se envían a servidores ni se borran automáticamente.

## Crear distribuciones en Windows

```powershell
# Sin dependencias de compilacion: genera el PS1 autonomo y metadatos
.\packaging\Build-Release.ps1 -Format Portable

# Con ps2exe 1.0.17 revisado y mt.exe de Windows SDK en PATH
.\packaging\Build-Release.ps1 -Format Exe

# Ademas requiere candle.exe y light.exe de WiX Toolset 3.x en PATH
.\packaging\Build-Release.ps1 -Format Msi
```

La construcción no descarga herramientas ni certificados. Puedes indicar una versión revisada de ps2exe con `-Ps2ExeVersion`. Salidas en `artifacts\4.0.0\<formato>` (ignoradas por Git), con hashes SHA-256. El icono está en `Assets/Suite.ico`.

El EXE oculta la **consola principal**, pero sigue dependiendo de Windows PowerShell/.NET/WPF: ps2exe no transforma el código en una aplicación nativa independiente ni oculta su fuente de forma segura. Las consolas de operaciones siguen siendo visibles deliberadamente. Puede generar avisos de SmartScreen/antivirus; no los desactives: valida y firma los paquetes para distribuirlos.

El MSI está diseñado para instalación por usuario en `%LOCALAPPDATA%\Programs\AdvancedToolSuite`, con acceso al menú Inicio, actualización mayor y desinstalación. Antes de desinstalar o mover el portable, retira el menú contextual desde Ajustes. Preferencias, auditoría e informes se conservan deliberadamente; las tareas programadas se administran aparte. **La compilación, actualización, desinstalación y firma requieren verificación en una VM Windows.**

## Pruebas y revisión

```sh
python -m unittest discover -s tests -v
```

En Windows PowerShell 5.1:

```powershell
.\tests\Validar-PowerShell.ps1
.\tests\Probar-Contratos.ps1
powershell.exe -NoProfile -STA -File .\Tool\AdvancedToolSuite.ps1 -SmokeTest
```

`-ValidateOnly` valida el catálogo sin cargar WPF. `-SmokeTest` construye las dos ventanas, iconos, temas, tarjetas y filtros sin mostrarlas ni ejecutar herramientas, usando una carpeta temporal. No sustituye las pruebas de interacción. Se incluye CI en `.github/workflows/validate.yml`, pendiente de ejecución remota.

- [Historial de cambios](CHANGELOG.md)
- [Metadatos de versión y estado de las 20 funciones](VERSION.json)
- [Revisión completa y próximas prioridades](docs/REVISION-3.0.md)
- [Plan de pruebas en Windows](docs/PRUEBAS-WINDOWS.md)

## Entrega 3.0.1: cinco pasos de distribución

1. **EXE y firma:** `packaging/manifest.xml`, incrustación con `mt.exe` y `packaging/Sign-Release.ps1` con certificado existente y sello de tiempo verificado.
2. **Instalación/desinstalación:** `install.ps1`/`uninstall.ps1` para paquetes Portable/Exe generados, por usuario, con WhatIf, recibo, hashes y entrada HKCU de desinstalación. No ejecutar sobre MSI ni sobre el repositorio sin construir el paquete.
3. **Pester:** `tests/ATS.Tests.ps1` tiene 43 casos; `tests/Run-Pester.ps1` exige 43/43 y genera informe para CI. Se usa el directorio `tests` existente; Windows no distingue `Tests` de `tests`.
4. **Documentación:** [MANUAL.md](MANUAL.md), [BUILD.md](BUILD.md), [CHANGELOG.md](CHANGELOG.md) y [LICENSE](LICENSE). Revisa titularidad del código heredado antes de publicar bajo la licencia elegida.
5. **v4:** [hoja de ruta](docs/ROADMAP-v4.0.0.md), planificación sin plugins/AD/gráficas nuevos ejecutándose en la versión actual.

Consulta la [revisión de entrega 3.0.1](docs/REVISION-3.0.1.md). **No se ha ejecutado Pester en Windows ni se han generado firmas o instaladores reales aquí.** Los resultados estáticos locales no sustituyen la validación de Windows.

## Inicio v4.0.0

La primera fase elegida es **plugins declarativos de diagnóstico**, no ejecución de código externo. El botón **Plugins v4** permite importar inactivo, aprobar por huella, ejecutar, desactivar y retirar. Consulta [Plugins/README.md](Plugins/README.md). Las demás funciones del roadmap siguen pendientes.

El autoextraíble contiene todas las fuentes, recursos, documentación y pruebas, salvo Git/cachés/datos privados y su propia salida. No instala la aplicación: para usarla basta `Tool/Iniciar.cmd` tras extraer. Se mantiene el PS1 principal autónomo.

```powershell
.\Releases\AdvancedToolSuite-v4.0.0-setup.ps1 -ValidateOnly
.\Releases\AdvancedToolSuite-v4.0.0-setup.ps1 -Launch
```

[Revisión de v4 y validación pendiente](docs/REVISION-4.0.0.md). El fichero generado no está firmado; sus hashes detectan incoherencias, no acreditan la procedencia del archivo entero.
