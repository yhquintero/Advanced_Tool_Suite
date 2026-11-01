# Instalación: «Cannot write to the registry key»

## Causa y corrección

El Portable ya se ha construido y validado. El fallo posterior al registrar la aplicación no implica necesariamente falta de permisos: `Get-Item HKCU:\...` entrega un objeto `RegistryKey` abierto para lectura y el instalador intentaba usar `SetValue` sobre él.

El instalador corregido abre explícitamente la subclave existente con `Registry.CurrentUser.OpenSubKey(..., true)`, conserva los tipos de valor y cierra cada handle en `finally`. La restauración de la entrada anterior utiliza el mismo escritor. La copia para recuperación conserva los ExpandString sin expandir y los valores vacíos/predeterminados.

No se cambia HKLM, no se modifican ACL, no se desactiva UAC ni se pide elevación. Si una política real impide escribir en HKCU, ese bloqueo sigue siendo un error; el código no lo elude.

## Cómo reintentar

1. Incorpora la revisión corregida de `install.ps1` **y** `packaging/Deployment.Common.ps1`; actualizar solo uno no basta. Si la corrección ya está fusionada y trabajas en `main`, usa `git pull --ff-only` sin descartar tus cambios locales.
2. Desde la raíz, en una cuenta estándar de Windows 10/11 x64:

   ```powershell
   .\install.ps1 -WhatIf
   .\install.ps1
   ```

3. La ejecución normal genera otro Portable en una salida única. No reutilices el instalador o helper de una distribución antigua: también contiene el defecto. Para un paquete firmado, reconstruye y vuelve a firmar; modificar sus scripts invalida hashes y firmas.

Al terminar debe aparecer el mensaje de instalación correcta, un acceso en Inicio y la entrada de Aplicaciones instaladas. La aplicación permanece en `%LOCALAPPDATA%\Programs\AdvancedToolSuite`.

Si el intento anterior dejó un error de recuperación, conserva cualquier `ATS-backup-*` y revisa `%LOCALAPPDATA%\AdvancedToolSuite\instalacion.log`. No borres manualmente entradas del Registro, recibos o carpetas para forzar la instalación. Los informes y preferencias son datos distintos de los archivos instalados.

## Comprobaciones de esta corrección

- 78 pruebas Python aprobadas, checker de repositorio y diff sin errores.
- Regresión nativa `tests/Probar-Registro-Instalacion.ps1`: clave HKCU aleatoria y temporal; escritura String/DWord, valores vacíos, ExpandString, MultiString y Binary, restauración tipada, rechazo de HKLM y de claves inexistentes, limpieza en `finally`.
- La regresión está conectada a CI bajo Windows PowerShell 5.1 y PowerShell 7 y puede ejecutarse en Windows Server sin simular soporte de la aplicación en Server.
- No se ha ejecutado aquí una instalación real, COM o Registro Windows: el entorno de desarrollo es Linux. Consulta los resultados de CI de la revisión concreta y valida el flujo completo en Windows 10/11 antes de considerarlo probado.
