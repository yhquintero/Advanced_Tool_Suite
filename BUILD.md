# Construcción, manifiesto y firma · NEXUS 4.0.0

## Estado y requisitos

Recetas preparadas; **no se ha generado ni firmado un EXE/MSI en este entorno Linux**. No se distribuyen certificados ni claves privadas. La compatibilidad real debe validarse en Windows 10/11 x64 con .NET Framework 4.8 y Windows PowerShell 5.1.

Herramientas del equipo de construcción:

| Operación | Dependencias |
| --- | --- |
| Portable | Windows PowerShell 5.1; sin módulos de compilación |
| EXE | ps2exe **1.0.17** y `mt.exe` de Windows SDK en PATH |
| MSI | Lo anterior y WiX Toolset **3.x** (`candle.exe`, `light.exe`) en PATH |
| Pruebas Pester | Pester **5.7.1** |
| Firma | Certificado propio vigente, clave privada accesible, EKU Code Signing y servidor de tiempo HTTPS |

Revisa la procedencia y licencia de las herramientas antes de instalarlas. El constructor no descarga dependencias. CI instala Pester desde PSGallery, no usa certificados ni secretos y no firma paquetes.

```powershell
# Instalacion explicita y consciente en el equipo de desarrollo
Install-Module ps2exe -RequiredVersion 1.0.17 -Repository PSGallery -Scope CurrentUser
Install-Module Pester -RequiredVersion 5.7.1 -Repository PSGallery -Scope CurrentUser

# mt.exe se instala con Windows SDK; WiX se instala por separado.
Get-Command mt.exe, candle.exe, light.exe
```

Usa una consola del SDK o agrega a PATH la carpeta x64 de sus herramientas revisadas. No ejecutes una copia desconocida de `mt.exe` encontrada en el proyecto.

## 1. Validación previa

```powershell
.\tests\Validar-PowerShell.ps1
.\tests\Probar-Contratos.ps1
.\tests\Run-Pester.ps1
powershell.exe -NoProfile -STA -File .\Tool\AdvancedToolSuite.ps1 -SmokeTest
```

Pester debe devolver **43/43 casos aprobados**, sin omitidos, y genera `artifacts\tests\ATS-Pester.xml`. Sus pruebas son unitarias/de contratos, no 43 ensayos de cambios administrativos sobre Windows. El smoke test carga controles WPF sin mostrarlos ni ejecutar herramientas.

## Instalación directa desde el repositorio

En Windows 10/11 x64, desde la raíz:

```powershell
.\install.ps1 -WhatIf  # no construye ni instala
.\install.ps1          # prepara Portable nuevo, valida e instala por usuario
```

La preparación usa Windows PowerShell 5.1, sin descargas, en `artifacts\<versión>\Portable-install-<GUID>`. Conserva esa salida para inspección; no sobrescribe paquetes anteriores. Confirma que confías en las fuentes antes de ejecutarlas. No se genera una firma ni se eluden políticas.

Para resolver el error antiguo «Selecciona una distribución completa…» sin actualizar aún el instalador:

```powershell
powershell.exe -NoProfile -File .\packaging\Build-Release.ps1 -Format Portable
powershell.exe -NoProfile -File .\install.ps1 -SourceDirectory .\artifacts\4.0.0\Portable
```

Si la salida ya existe y no está vacía, consérvala con otro nombre antes de reconstruir. No crees un `SHA256.json` manual para omitir la validación.

## 2. Construcción sin firma

Desde la raíz del repositorio:

```powershell
.\packaging\Build-Release.ps1 -Format Portable
.\packaging\Build-Release.ps1 -Format Exe
.\packaging\Build-Release.ps1 -Format Msi
```

Las salidas están en `artifacts\4.0.0\Portable`, `Exe` o `Msi`. La carpeta del formato debe estar **vacía** antes de construir. Archiva o retira conscientemente una salida anterior; el constructor no la borra para evitar pérdida de archivos o mezcla de binarios obsoletos. Una compilación fallida puede dejar una salida parcial: no la distribuyas.

Puedes elegir otra carpeta nueva o vacía con `-OutputDirectory "ruta"`; es lo que usa la preparación automática.

El portable sigue siendo un único `AdvancedToolSuite.ps1` para ejecutar. Los documentos y scripts adicionales son opcionales para la instalación gestionada.

## 3. Manifiesto del ejecutable

Fuente: **`packaging/manifest.xml`**.

- `asInvoker` y `uiAccess=false`: el panel no pide administrador al arrancar.
- Compatibilidad Windows 10/11, arquitectura amd64.
- `PerMonitorV2,PerMonitor` y fallback DPI.
- Rutas largas habilitadas; las políticas y APIs concretas de Windows siguen aplicando.

El flujo de construcción es:

1. ps2exe genera el EXE con `STA`, x64, icono y sin consola principal.
2. `mt.exe` incrusta `manifest.xml` en el recurso **#1**.
3. Se extrae el recurso y se comprueba `asInvoker`.
4. Solo entonces se firma el EXE.
5. Para MSI, WiX empaqueta el EXE ya firmado y después se firma el MSI.
6. Finalmente se calculan los hashes de los archivos distribuidos.

**Modificar el EXE después de firmarlo invalida la firma.** El manifiesto no se pasa como un parámetro inexistente de ps2exe. La compilación no agrega privilegios globales ni omite políticas de ejecución.

ps2exe es un contenedor de PowerShell: no elimina la dependencia de Windows PowerShell/.NET/WPF, no protege el código como un secreto y no garantiza ausencia de avisos antivirus. Las consolas de operaciones siguen siendo visibles deliberadamente.

## 4. Authenticode con un certificado existente

Consulta certificados del **usuario actual** sin exportar claves:

```powershell
Get-ChildItem Cert:\CurrentUser\My |
    Select-Object Subject, Thumbprint, NotBefore, NotAfter, HasPrivateKey
```

Elige un certificado autorizado para firma de código. No compartas PFX, claves ni contraseñas en chat, Git o registros. Para una publicación confiable se necesita una cadena de confianza adecuada; un certificado autofirmado no aporta confianza pública por sí mismo.

```powershell
$huella = Read-Host 'Huella de 40 caracteres de tu certificado de firma'
$tiempo = Read-Host 'URL HTTPS del servidor de sello de tiempo aprobado'

.\packaging\Build-Release.ps1 -Format Exe `
    -CertificateThumbprint $huella -TimestampServer $tiempo

# Usa una carpeta Msi vacia; vuelve a construir e incrusta antes de firmar
.\packaging\Build-Release.ps1 -Format Msi `
    -CertificateThumbprint $huella -TimestampServer $tiempo
```

También puedes construir un portable firmado con esos parámetros. Se firman los `.ps1` distribuidos y el EXE antes de empaquetar el MSI. `Sign-Release.ps1` exige:

- clave privada accesible;
- certificado vigente y EKU `1.3.6.1.5.5.7.3.3`;
- SHA-256 y servidor de sello de tiempo HTTPS;
- estado `Valid`, certificado de sello presente y verificación posterior.

Si falla una condición, la construcción falla; no se etiqueta un archivo parcialmente firmado como válido. Un token/HSM puede pedir autorización mediante su proveedor. No se automatiza esa credencial.

```powershell
# Inspeccion posterior independiente
Get-AuthenticodeSignature .\artifacts\4.0.0\Exe\AdvancedToolSuite.exe |
    Format-List Status, StatusMessage, SignerCertificate, TimeStamperCertificate
```

El helper `packaging/Sign-Release.ps1` sirve para firmar archivos individuales con los mismos parámetros y admite `-WhatIf`. Si firmas después de generar `SHA256.json`, los hashes quedan obsoletos: reconstruye mediante el flujo anterior, no distribuyas ambos sin regenerarlos.

## 5. Instalación gestionada por scripts

**Solo para las distribuciones Portable/Exe generadas**, no para el árbol de fuentes sin `SHA256.json`:

```powershell
# Dentro de artifacts\4.0.0\Portable o Exe
.\install.ps1 -WhatIf
.\install.ps1

# Si la distribucion esta firmada y confias en su editor
.\install.ps1 -RequireSignature

# Desde la raiz del repositorio tambien puedes indicar el paquete
.\install.ps1 -SourceDirectory .\artifacts\4.0.0\Portable
```

Destino fijo: `%LOCALAPPDATA%\Programs\AdvancedToolSuite`. Crea acceso en Inicio y registro de desinstalación en:

`HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\AdvancedToolSuite.Nexus`.

No requiere administrador, no modifica HKLM, no cambia políticas y no usa un directorio de destino arbitrario. Comprueba los hashes, rechaza symlinks/junctions de la cadena de carpetas y conserva un recibo con hashes de archivos gestionados. La actualización rechaza downgrade, archivos modificados o archivos ajenos; usa una carpeta de preparación y backup para intentar rollback si falla el registro o el acceso directo.

`-RequireSignature` verifica confianza Authenticode de scripts/EXE del paquete. **No fija una identidad de editor aprobada**; además comprueba el Subject/Thumbprint por un canal de confianza. `SHA256.json` detecta incoherencias, pero no es un manifiesto firmado: cualquiera que pueda reemplazar paquete y manifiesto puede recalcularlo. Nunca ejecutes primero un instalador de origen desconocido confiando en que se autentique a sí mismo.

Desinstalación:

```powershell
& "$env:LOCALAPPDATA\Programs\AdvancedToolSuite\uninstall.ps1" -WhatIf
& "$env:LOCALAPPDATA\Programs\AdvancedToolSuite\uninstall.ps1"
```

Pide confirmación. Solo borra los archivos enumerados por un recibo válido y cuyos hashes coinciden; si un archivo fue modificado, detiene la retirada para revisión. Conserva archivos ajenos, logs, preferencias, informes y tareas. Solo retira el acceso directo y la entrada contextual que apunten a esta copia. No tiene opción de purgar datos ni de borrar rutas elegidas por el usuario.

El registro de instalación está en `%LOCALAPPDATA%\AdvancedToolSuite\instalacion.log`, UTC, con rotación de una copia al superar 1 MiB. Cierra la suite y sus herramientas antes de actualizar/desinstalar. No mezcles MSI e instalación por scripts; desinstala el método anterior primero. Si el rollback falla por permisos o archivos bloqueados, conserva el backup `ATS-backup-*` y revisa manualmente antes de volver a ejecutar.

## 6. MSI, licencia y aceptación

MSI usa WiX 3.x, instalación por usuario, acceso al menú Inicio, comprobación de .NET y actualización mayor. No ejecuta `install.ps1` ni `uninstall.ps1`: Windows Installer gestiona su propio inventario. Los scripts del paquete Msi rechazan ese formato. El MSI bloquea la coexistencia con una instalación registrada por scripts en la misma ruta.

La licencia del proyecto está en `LICENSE`; comprueba titularidad de código heredado y licencias de terceros antes de publicar. MIT no relicencia herramientas de Microsoft ni dependencias externas.

Antes de distribuir: ejecutar la matriz de `docs/PRUEBAS-WINDOWS.md`, probar instalación nueva, actualización, downgrade bloqueado, rollback y desinstalación en VM, validar firmas y hashes, y guardar evidencia. Ni un XML válido ni un CI de contratos sustituyen esas pruebas.

## 7. Regenerar el único autoextraíble v4

Requiere Python 3.10+ para generar, no para ejecutar el fichero final:

```sh
python packaging/Build-Bootstrap.py
python -m unittest discover -s tests -v
```

Genera `Releases/AdvancedToolSuite-v4.0.0-setup.ps1`. La salida se debe regenerar **después de cualquier cambio** de los archivos incluidos. Las pruebas comparan cada archivo embebido con su fuente y detectan una salida obsoleta. ZIP y metadatos ordenados usan valores fijos para reproducibilidad dentro del mismo entorno Python/zlib; no se promete igualdad de compresión entre todas las versiones de zlib.

La salida no se incluye a sí misma. El proyecto extraído incluye plantilla/generador para volver a crearla. No contiene `.git`, cachés, informes privados ni paquetes EXE/MSI compilados. El PS1 final funciona sin Python ni módulos externos: usa compresión incluida en .NET. Verifica todo antes de escribir, exige destino nuevo y publica el árbol con un movimiento de directorio, no una combinación de archivos.

En Windows:

```powershell
.\Releases\AdvancedToolSuite-v4.0.0-setup.ps1 -ValidateOnly
.\Releases\AdvancedToolSuite-v4.0.0-setup.ps1 -Destination "$env:USERPROFILE\Desktop\ATS-v4" -WhatIf
.\Releases\AdvancedToolSuite-v4.0.0-setup.ps1 -Destination "$env:USERPROFILE\Desktop\ATS-v4" -Launch
.\tests\Probar-Plugins.ps1
```

El extractor **no está firmado aquí**. Para publicar una copia firmada, usa `Sign-Release.ps1` con tu certificado autorizado después de generarlo. La regeneración elimina esa firma, por lo que debe firmarse de nuevo. Las pruebas de contenido aceptan el bloque de firma agregado al final, pero la reproducibilidad binaria se comprueba sobre la salida sin firmar. No publiques claves o certificados privados.
