# Historial de versiones

Este archivo registra cambios de código. La auditoría de uso se guarda por separado; no contiene contraseñas ni certifica el resultado de herramientas externas.

## Sin publicar — presentación y seguridad del repositorio

- README reorganizado, guía de inicio segura, estado explícito de desarrollo y límites verificables.
- MIT canónica y traducción española separada, avisos de terceros y conservación de derechos heredados.
- SECURITY, CONTRIBUTING, CODEOWNERS, plantillas de incidencias/PR y Dependabot para acciones.
- CI fijado por SHA, sin credenciales persistidas, tiempos máximos y permisos mínimos.
- Web estática responsive, sin JavaScript/analítica/formularios, CSP por meta y navegación accesible.
- Workflow Pages manual desde main, con permisos de publicación separados; no se afirma despliegue activo.
- About propuesto de 255/350 caracteres, topics y Website real provisional. API administrativa devolvió 403: cambios remotos pendientes, no aplicados.
- Checker local de enlaces, metadatos, web, referencias de acciones y patrones básicos de secretos. No sustituye auditoría.
- Autoextraíble regenerado con web/políticas y pruebas; documentos legales/de seguridad incorporados a paquetes.

## 4.0.0 — 2026-11-01 · inicio de desarrollo

**Estado:** primera fase implementada, pendiente de validación Windows. No representa la culminación del roadmap v4 ni una versión certificada para producción.

- Un único autoextraíble: `Releases/AdvancedToolSuite-v4.0.0-setup.ps1`, con árbol de fuentes, recursos, documentación, plugins de ejemplo y pruebas embebidos.
- Extracción sin Internet ni administrador; SHA256 global y por archivo, límites de tamaño, rutas validadas, staging y rechazo de destinos existentes. `-ValidateOnly`, `-WhatIf` y apertura opcional con `-Launch`.
- Generador reproducible Python sin dependencias: `packaging/Build-Bootstrap.py`; excluye Git, cachés, informes de usuario y el propio archivo generado para evitar recursión.
- Botón **Plugins v4**, importación inactiva, aprobación explícita por SHA256, desactivación, retirada y ejecución bajo el despacho existente.
- Plugins declarativos de esquema v1: solo diagnósticos internos 1/14/19/27/28/30. No ejecuta PS1/DLL/EXE externos, no acepta comandos libres y no descarga nada automáticamente.
- Núcleo de plugins embebido en el PS1 autónomo y fuente editable en `Plugins/Plugin.Core.ps1`; esquema y dos ejemplos incluidos.
- Eventos de plugins en auditoría, restricciones del modo solo lectura y controles de clave local para cambiar el almacén/aprobaciones.
- Pruebas de integridad y correspondencia del autoextraíble, sincronización del núcleo, contratos nativos de plugins y pasos adicionales de CI Windows.
- `LEEME-PRIMERO.md` y `docs/REVISION-4.0.0.md` explican uso, alcance y validación pendiente.
- i18n ES/EN/PT, gráficas, editor visual de temas, AD, workflows y host de código externo permanecen pendientes.

## 3.0.1 — 2026-11-01

**Estado:** scripts y documentación preparados; ejecución Pester/CI Windows, instalación real, compilación y firma pendientes. No se publica un EXE/MSI firmado desde este entorno.

### Distribución y firma

- `packaging/manifest.xml`: asInvoker, sin UIAccess, amd64, compatibilidad Windows 10/11, DPI y rutas largas.
- Constructor EXE: incrusta/extráe el manifiesto con Windows SDK `mt.exe` antes de firmar; comprueba código de salida y nivel de ejecución.
- `packaging/Sign-Release.ps1`: certificado existente con clave privada y EKU Code Signing, SHA256, sello HTTPS y verificación de firma/sello. No almacena credenciales ni genera certificados.
- Firma opcional de los scripts/EXE antes del empaquetado y del MSI después; hashes finales calculados tras firmar.
- Se rechaza reconstruir sobre una salida no vacía para evitar archivos obsoletos.

### Instalación por usuario

- `install.ps1` y `uninstall.ps1`, con WhatIf y recibo de hashes, acceso a Inicio y registro HKCU de desinstalación.
- Destino fijo en el perfil, validación de paquete, rechazo de rutas enlazadas y de archivos gestionados modificados.
- Actualización sin downgrade; staging/backup e intento de rollback ante fallo de registro/acceso directo.
- Retirada limitada a archivos gestionados; conserva datos, tareas e integraciones de otras copias.
- `instalacion.log` UTC, una copia al superar 1 MiB; separación explícita entre MSI e instalación por scripts.

### Pruebas, documentación y planificación

- `tests/ATS.Tests.ps1`: **43 casos Pester**, contratos y funciones puras, sin ejecutar acciones administrativas.
- Runner Pester 5.7.1: exige 43 aprobadas, cero omitidas, informe NUnit XML y paso dedicado en CI Windows.
- `MANUAL.md`, `BUILD.md`, licencia MIT en español y revisión de titularidad heredada indicada antes de publicar.
- `docs/ROADMAP-v4.0.0.md`: plugins, i18n, gráficas, Active Directory y workflows, marcados como planificación no implementada.
- Metadatos y versión de la aplicación alineados a 3.0.1; revisión adicional en `docs/REVISION-3.0.1.md`.

## 3.0.0 — 2026-11-01

**Estado:** implementación y recursos preparados; validación visual/funcional en Windows y compilación EXE/MSI pendientes. No se publican binarios precompilados.

### Mejoras en el orden solicitado

1. **Entrada animada:** fade y desplazamiento de tarjetas y navegación; respeta la preferencia de movimiento y la configuración del sistema.
2. **Iconos SVG:** 42 diseños vectoriales originales, uno por herramienta; geometrías embebidas en el `.ps1` y fuentes editables en `Assets/Icons`.
3. **Temas:** Neón azul, Púrpura cyberpunk, Verde Matrix y Rojo gaming, con selección persistente.
4. **Compacto:** ventana de 410 px con navegación por selector de categoría y regreso al modo completo desde Ajustes.
5. **Fondo:** gradiente ambiental animado, sin librerías ni partículas de alto consumo; se puede desactivar.
6. **Búsqueda:** filtrado inmediato combinado con categoría y favoritos.
7. **Favoritos:** estrellas por herramienta, persistencia por usuario y filtro dedicado.
8. **Historial exportable:** exportación `.log` incluyendo las cinco copias rotadas disponibles.
9. **Programación GUI:** asistente de informes de sistema únicos, fecha validada, ejecución limitada y sesión interactiva; sin credenciales almacenadas ni comandos arbitrarios.
10. **Verificación previa:** existencia de componentes y ejecutables, unidad y FAT32, espacio libre y tipo físico cuando es identificable por número de serie.
11. **Estado:** CPU, RAM y espacio libre del disco del sistema cada tres segundos, consultados en un runspace sin bloquear WPF.
12. **Deshacer:** último valor de registro de ajustes internos, incluyendo valor/tipo originales o ausencia; lista blanca de rutas y detección de cambios externos.
13. **Auditoría:** JSONL local y copia en `C:\REPORTE\audit.log` cuando es escribible, con fecha UTC, usuario, equipo, versión, sesión, acción y estado.
14. **Solo lectura:** lista conservadora de diagnósticos; bloquea consolas de administración, paneles de edición, tareas, restauración y deshacer desde la suite.
15. **Clave local:** PasswordBox, PBKDF2-HMAC-SHA256 con sal aleatoria, DPAPI por usuario y bloqueo tras cinco fallos. Es protección contra accidentes, no control de acceso del sistema.
16. **Restauración:** creación manual o requisito previo opcional para cambios compatibles; se comprueba un punto nuevo y se cancela el cambio si falla.
17. **EXE:** receta con ps2exe, STA, icono propio, ventana principal sin consola y sin elevar todo el programa. Compilación pendiente en Windows.
18. **MSI:** receta WiX 3.x, instalación por usuario, acceso al menú Inicio, icono y detección de .NET 4.8. Compilación e instalación pendientes en Windows.
19. **Portable:** `.ps1` autónomo con XAML e iconos embebidos; construcción de distribución con manifiesto SHA-256.
20. **Explorador:** instalar/retirar entrada de clic derecho sobre el fondo de carpetas en HKCU; rutas entrecomilladas y sin cambios para otros usuarios.

### Registro y calidad

- `VERSION.json`: versión y estado de las 20 funciones, legibles por herramientas.
- `versiones.log`: resumen de versiones utilizadas, generado localmente una vez por versión.
- Actividad y auditoría: rotación al superar 5 MiB, cinco copias por archivo y advertencias si falla la escritura.
- La interfaz distingue solicitudes, cancelaciones, errores, cambios internos y fin de procesos de consola.
- Las consolas devuelven un código de salida monitorizado; cerrar la suite no garantiza cancelar trabajos ya iniciados.
- Se fijan rutas de aplicaciones del sistema para no lanzar ejecutables homónimos del directorio de trabajo.
- Se preservan otros valores del Registro y se rechaza borrar una clave del menú contextual con contenido ajeno.
- Pruebas estáticas ampliadas, contratos PowerShell sin cambios del sistema, prueba WPF no interactiva y flujo CI de Linux/Windows.
- Revisión detallada en `docs/REVISION-3.0.md` y plan de validación en `docs/PRUEBAS-WINDOWS.md`.

## 2.0 — 2026-11-01

- Primera interfaz WPF en español: tarjetas redondeadas, búsqueda, categorías y registro.
- Migración de las 41 opciones originales, más cancelación de apagado pendiente.
- UAC por acción y confirmación para cambios delicados.
- Sustitución de optimizaciones ficticias y borrados masivos por diagnóstico y herramientas oficiales.
- Inventarios CIM en Documentos y conservación del `.bat` original.

## Base heredada — 1.x

- Menú de consola `Tool/Tool.bat` con 41 opciones administrativas.
- Se conserva sin modificaciones como referencia histórica; no incorpora los controles de la versión gráfica.
