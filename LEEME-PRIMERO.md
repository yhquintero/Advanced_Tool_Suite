# ATS v4.0.0 · Un solo fichero para crear todo el proyecto

## Lo que debes conservar o compartir

**`Releases/AdvancedToolSuite-v4.0.0-setup.ps1`** es el único archivo necesario para reconstruir el proyecto. Contiene los scripts, la interfaz, iconos, plugins de ejemplo, documentación, pruebas y recetas de construcción, comprimidos dentro del propio `.ps1`. No descarga archivos de Internet.

Esta es una **versión de inicio de desarrollo v4**, no una versión certificada para producción. Se mantienen pendientes las pruebas reales en Windows, Pester/CI y compilación/firma de paquetes.

## Ejecutarlo en Windows

Guarda ese único archivo en una carpeta de tu usuario, revisa su procedencia y abre Windows PowerShell 5.1:

```powershell
# Verifica el contenido sin escribir ni abrir herramientas
powershell.exe -NoProfile -File .\AdvancedToolSuite-v4.0.0-setup.ps1 -ValidateOnly

# Crea AdvancedToolSuite-v4.0.0 junto al archivo
powershell.exe -NoProfile -File .\AdvancedToolSuite-v4.0.0-setup.ps1

# Opcional: elige otro destino NUEVO y abre el panel al terminar
.\AdvancedToolSuite-v4.0.0-setup.ps1 `
    -Destination "$env:USERPROFILE\Desktop\ATS-v4" -Launch

# Solo simula la extraccion (no crea carpetas)
.\AdvancedToolSuite-v4.0.0-setup.ps1 -Destination "$env:USERPROFILE\Desktop\ATS-v4" -WhatIf
```

La carpeta padre del destino debe existir. Si el destino ya existe, incluso vacío, el extractor se detiene: elige otro nombre. **Nunca combina ni sobrescribe un proyecto anterior.** No tiene opción Force.

Si Windows bloquea un archivo descargado, revisa su contenido y origen antes de desbloquearlo. El script no omite políticas ni pide administrador. Las políticas de tu organización pueden impedir su ejecución: no las eludas.

## Qué crea

```text
AdvancedToolSuite-v4.0.0/
  LEEME-PRIMERO.md
  README.md, MANUAL.md, BUILD.md, CHANGELOG.md, LICENSE, VERSION.json
  install.ps1, uninstall.ps1
  Tool/          aplicación WPF y lanzadores
  Assets/        iconos SVG y el icono de distribución
  Plugins/       núcleo declarativo, esquema JSON y ejemplos
  docs/          revisiones, pruebas y hoja de ruta
  packaging/     constructores, firma, plantilla y generador de este fichero
  tests/         pruebas Python, Pester y contratos PowerShell
  .github/       definición de CI
```

No incluye `.git`, credenciales, historial de Git, informes personales, logs de uso, cachés, dependencias descargadas ni binarios EXE/MSI compilados. Es el árbol de fuentes y recursos del proyecto, no una copia de tus datos de Windows.

**Extraer no instala el programa:** no crea entradas de registro, tareas, accesos directos ni plugins activos. No ejecuta diagnósticos. `-Launch` es una opción explícita para abrir el panel después de extraer.

## Abrir la aplicación

Dentro del proyecto creado, ejecuta **`Tool\Iniciar.cmd`**. Requiere Windows 10/11 x64, Windows PowerShell 5.1 y .NET Framework 4.8.

El botón **Plugins v4** permite importar, revisar y activar un ejemplo de `Plugins\Examples`. Importar lo deja inactivo. Solo admite diagnósticos internos permitidos, nunca scripts/EXE/DLL externos. La aprobación está ligada a su hash; editar el manifiesto obliga a revisarlo de nuevo. Consulta `Plugins/README.md`.

## Integridad y seguridad

El extractor comprueba SHA256 del archivo comprimido y de cada archivo, valida rutas y límites de tamaño, usa una carpeta temporal y solo publica el destino completo al terminar. Rechaza enlaces/junctions de la cadena del destino. Si falla, intenta limpiar únicamente su temporal, no un proyecto existente.

Los hashes embebidos detectan incoherencias, **no acreditan la identidad del autor**: alguien que reemplace el `.ps1` entero puede recalcularlos. Confía en el origen del fichero y, para distribuir de forma estable, firma el extractor con Authenticode y verifica su firmante. Este fichero no está firmado aquí.

Las verificaciones estáticas del contenido no sustituyen una extracción e interacción reales en Windows. Para instalar de forma gestionada o compilar EXE/MSI, sigue `BUILD.md` después de extraer.
