# Manual de usuario · Advanced Tool Suite NEXUS 4.0.0

## 1. Qué incluye esta versión

Aplicación local de administración y diagnóstico para Windows, con 42 herramientas, panel WPF, temas, favoritos, monitor de recursos y registros. La implementación está preparada para validación; **las pruebas interactivas de Windows y la compilación/firma EXE/MSI siguen pendientes en este entorno**.

Requisitos: Windows 10/11 **x64 de escritorio**, Windows PowerShell 5.1 y .NET Framework 4.8. No usar PowerShell 7 como sustituto de la plataforma soportada. No compatible con Linux, macOS ni Server Core.

## 2. Elegir modo de uso

### Portable

En el repositorio, abre `Tool/Iniciar.cmd`, o ejecuta:

```powershell
powershell.exe -NoProfile -STA -File .\Tool\AdvancedToolSuite.ps1
```

En una distribución portable basta con su `AdvancedToolSuite.ps1`; el XAML y los iconos ya están embebidos. El `.bat` original es solo histórico y no tiene los controles de seguridad de la versión gráfica.

### Instalación por usuario

Desde la raíz del repositorio, `install.ps1` reconoce las fuentes y prepara automáticamente un paquete Portable sin firma en una carpeta nueva `artifacts\<versión>\Portable-install-<GUID>`. Después valida sus hashes e instala. No descarga dependencias ni reutiliza distribuciones antiguas. `-WhatIf` no construye ni instala. Si usas PowerShell 7, la preparación se delega a Windows PowerShell 5.1.

También admite una distribución Portable/Exe ya construida según `BUILD.md`, con `SHA256.json`, scripts y helper: `./install.ps1 -SourceDirectory "ruta-al-paquete"`. Un paquete incompleto o alterado se rechaza; no se regenera su manifiesto. Con `-RequireSignature`, prepara y firma una distribución previamente: no se generan fuentes sin firma automáticamente.

```powershell
.\install.ps1 -WhatIf
.\install.ps1
```

Instala en `%LOCALAPPDATA%\Programs\AdvancedToolSuite`, agrega acceso a Inicio y registro en Aplicaciones instaladas. No requiere administrador ni cambia políticas. Una distribución con firmas de confianza puede verificarse con `-RequireSignature`. Primero verifica el origen del instalador por un canal confiable: no puede autenticarse a sí mismo contra un atacante que reemplace todo el paquete.

### MSI

Usa el MSI cuando esté construido y validado en Windows; no invoques los scripts de instalación para ese formato. No mezcles métodos de instalación en la misma ubicación. Consulta `BUILD.md`.

## 3. Panel y preferencias

- **Categorías:** selecciona en la barra izquierda o en el desplegable sobre los accesos rápidos.
- **Buscar:** filtra nombre, descripción y categoría en tiempo real.
- **Estrella:** marca/quita favorito sin ejecutar la herramienta. **Favoritos** alterna el filtro.
- **Ajustes:** Neón azul, Púrpura cyberpunk, Verde Matrix o Rojo gaming; animaciones, compacto, solo lectura y restauración previa.
- **Compacto:** ancho de 410 px; categoría y Ajustes continúan disponibles.
- **Animaciones:** entrada y gradiente ambiental, desactivables; también respetan la configuración de movimiento de Windows.
- **Estado:** CPU, RAM y espacio libre del disco del sistema cada tres segundos. Si CIM no responde, se informa indisponibilidad; no se inventan lecturas.
- **Actualizar:** refresca resumen y catálogo, no cancela operaciones ni repara Windows automáticamente.

Las preferencias y favoritos se guardan en el perfil del usuario. No copies el archivo DPAPI de protección a otra cuenta: no se podrá descifrar allí.

## 4. Ejecutar herramientas con seguridad

La etiqueta **UAC** indica que la suite solicita elevación para esa acción. El panel debe iniciarse como usuario estándar. Cancelar UAC no concede permisos ni ejecuta la operación.

Las tarjetas **PRECAUCIÓN** piden confirmación. Apagado y reinicio son inmediatos después de aceptar: guarda trabajo antes. La conversión FAT32 a NTFS exige además escribir el volumen exacto. Haz una copia de seguridad; ni Deshacer ni un punto de restauración revierten esa conversión.

Las operaciones largas abren una consola separada con su resultado. Pulsa Entrar cuando termines de revisarlo. El panel registra el código de salida al cerrarse la consola; un cierre externo no demuestra éxito. Cerrar el panel no cancela trabajos ya lanzados.

**No hay optimización mágica:** memoria muestra consumo; energía abre los planes; limpieza abre la herramienta oficial; CHKDSK se lanza en modo lectura. La salud reportada por el disco no garantiza ausencia de fallos.

## 5. Solo lectura, clave y restauración

### Solo lectura

Permite ocho diagnósticos: información del sistema, CHKDSK de lectura, memoria, salud de discos, configuración IP, ping estándar, ping a un destino e inventario. Escribir un informe o log local sigue siendo posible. Se bloquean terminales, paneles de edición, cambios internos, programación, integración, restauración y deshacer.

**No es control de acceso del sistema.** Un usuario con acceso al código o a su perfil puede modificar el modo. Usa cuentas limitadas y políticas de Windows para restricciones reales.

### Clave local

En Ajustes configura una clave de al menos diez caracteres, confirmada dos veces. Se almacena un hash con sal protegido por DPAPI, no la contraseña en texto. Cinco fallos bloquean cinco minutos. Cambiar o retirar una clave existente exige la actual.

Protege contra cambios accidentales, no frente a la misma cuenta, un administrador o código malicioso. Eliminar el archivo de protección permite reiniciarla: no es autenticación empresarial ni una contraseña de Windows. No compartas claves en reportes ni incidencias.

### Puntos de restauración

Puedes crear uno manualmente o exigirlo antes de cambios internos compatibles. Se verifica un punto nuevo; si falla o se cancela UAC, no continúa el cambio. Windows puede limitar la frecuencia y requiere Protección del sistema activada. La suite no desactiva ese límite.

No cubre modificaciones que hagas dentro de Regedit, Administración de discos u otras ventanas externas. No sustituye una copia de datos.

## 6. Deshacer Registro

El botón restaura **un nivel** del último ajuste interno de archivos ocultos, tema de aplicaciones o menú contextual clásico/moderno. Guarda valor, tipo y ausencia previa. Si el valor o tipo ha cambiado desde otra herramienta, rechaza sobrescribirlo.

No revierte cambios de Regedit, firewall, conversión, archivos borrados ni toda una rama del Registro. Algunos cambios requieren cerrar sesión o reiniciar Explorador. Pueden conservarse claves padre vacías. No es una transacción garantizada ante un cierre inesperado.

## 7. Programar un informe

1. Pulsa **Programar** (o la tarjeta correspondiente).
2. Introduce una fecha futura local en formato `yyyy-MM-dd HH:mm`.
3. Revisa y confirma.
4. Se registra una tarea `ATS-Informe-*`, limitada y con sesión interactiva, sin guardar credenciales.
5. Consulta el informe en `Documentos\AdvancedToolSuite\Programados`.

No permite comandos libres ni se ejecuta como SYSTEM. La sesión debe estar iniciada; las reglas de disponibilidad de Windows determinan cuándo se recupera un disparo perdido. Gestiona historial/eliminación desde el Programador de tareas (`taskschd.msc`). Desinstalar no borra estas tareas automáticamente.

## 8. Informes y registros

Inventario manual: `Documentos\AdvancedToolSuite\Reportes`. Puede incluir usuario, red y números de serie; revisa antes de compartir.

En `%LOCALAPPDATA%\AdvancedToolSuite`:

| Archivo | Uso |
| --- | --- |
| `actividad.log` | Fecha/hora local, mensaje y estado; exportable desde el panel |
| `audit.jsonl` | Eventos estructurados UTC, versión, sesión, usuario, equipo e ID de acción |
| `versiones.log` | Resumen de las versiones utilizadas |
| `instalacion.log` | Instalaciones/desinstalaciones, UTC; una copia rotada al superar 1 MiB |
| `preferencias.json` | Configuración y favoritos |
| `registro-undo.clixml` | Última copia de un valor interno de Registro |
| `proteccion.dpapi` | Protección local y estado de bloqueo |

Actividad/auditoría: rotación al superar 5 MiB y cinco copias. **Exportar log** reúne el historial legible disponible, no todos los informes ni todas las auditorías. Se intenta una copia secundaria en `C:\REPORTE\audit.log`; si faltan permisos, se avisa y continúa la copia local, sin cambiar ACL.

`REQUEST` es una solicitud; `DISPATCHED` significa enviado, no completado. `REGISTRY_OK` corresponde a un cambio interno aplicado. `PROCESS_EXIT_OK/ERROR` informa la salida de la consola. Los registros son editables, no firmados ni inmutables. Si fallan todas las escrituras no puede garantizarse un historial completo.

## 9. Menú contextual

Ajustes permite instalar/retirar **Advanced Tool Suite** en el clic derecho del fondo de carpetas, solo para este usuario. En Windows 11 puede estar en **Mostrar más opciones**. Si mueves la copia portable, reinstala la entrada. El desinstalador por scripts retira únicamente la entrada que apunte a su copia; el MSI requiere retirarla desde Ajustes antes de desinstalar.

## 10. Actualizar y desinstalar

Cierra la suite y sus consolas. Para actualizar una instalación por scripts, ejecuta `install.ps1` de la nueva distribución. Rechaza downgrade, archivos gestionados modificados, enlaces de sistema de archivos y archivos ajenos en el destino. Se intenta recuperar la instalación anterior si falla el registro o el acceso directo; si el rollback falla, conserva `ATS-backup-*` para recuperación manual.

```powershell
& "$env:LOCALAPPDATA\Programs\AdvancedToolSuite\uninstall.ps1" -WhatIf
& "$env:LOCALAPPDATA\Programs\AdvancedToolSuite\uninstall.ps1"
```

La retirada pide confirmación. Un archivo gestionado con hash cambiado bloquea la operación para revisión. Se conservan preferencias, informes, logs y tareas, así como archivos ajenos. No existe borrado masivo de datos. MSI debe retirarse desde su entrada de Windows Installer, no con el script.

## 11. Solución de problemas

| Síntoma | Qué revisar |
| --- | --- |
| Política bloquea el PS1 | Revisa el archivo y las políticas de tu organización; no las omitas indiscriminadamente |
| Herramienta no disponible | Edición/componentes de Windows, rutas del sistema y permisos; Defender puede estar reemplazado por otro antivirus |
| No hay punto nuevo | Protección del sistema, espacio, límite de frecuencia y cancelación UAC |
| Disco sin tipo | Número de serie no disponible/único, RAID o virtualización; no deducir SSD por el nombre |
| EXE no confiable | Origen, firma, cadena, sello y análisis; no desactivar antivirus para ocultar el aviso |
| Fallo al instalar | Paquete completo generado, SHA256, permisos, archivos bloqueados y `instalacion.log` |
| No se puede desinstalar | Recibo ausente, hash cambiado o enlace; conservar datos y revisar antes de borrar manualmente |

## 12. Ayuda y versiones futuras

`CHANGELOG.md` registra cambios publicados de código; `BUILD.md` explica construcción y firma; `docs/PRUEBAS-WINDOWS.md` contiene la matriz pendiente. La hoja de ruta `docs/ROADMAP-v4.0.0.md` distingue la primera fase declarativa disponible del resto de funciones todavía planificadas.

## 13. Inicio v4: un único autoextraíble y plugins

Puedes distribuir solo `Releases/AdvancedToolSuite-v4.0.0-setup.ps1`. Al ejecutarlo crea todo el árbol en una carpeta nueva, sin descargas ni instalación automática. Consulta `LEEME-PRIMERO.md`. No reemplaza una copia existente; la apertura del panel requiere `-Launch` o iniciar manualmente `Tool/Iniciar.cmd`.

**Plugins v4** abre el gestor de manifiestos declarativos. Importar no activa ni ejecuta. Activa después de revisar el diagnóstico y ejecuta solo cuando lo solicites. Cambiar el archivo invalida su aprobación por SHA256. No es un host de scripts externos; solo admite diagnósticos permitidos. Ejemplos y límites en `Plugins/README.md`.

El resto de la hoja de ruta (i18n, gráficas, editor de temas, AD y workflows) sigue pendiente; esta versión es el inicio del desarrollo v4.
