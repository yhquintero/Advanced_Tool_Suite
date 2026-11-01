# Revisión · inicio v4.0.0

Fecha: **2026-11-01**. Primera fase de desarrollo, no una declaración de estabilidad ni de roadmap terminado.

## Entrega principal: un único fichero

`Releases/AdvancedToolSuite-v4.0.0-setup.ps1` contiene el árbol de fuentes y recursos completo. Al ejecutarlo en Windows PowerShell crea una carpeta nueva, con scripts, interfaz, iconos, plugins declarativos de ejemplo, manuales, historial, licencia, pruebas y herramientas de construcción.

No contiene Git, cachés, informes privados, dependencias descargadas ni EXE/MSI compilados. No se incluye a sí mismo para evitar recursión; sí incluye plantilla y generador para reconstruirlo.

### Controles del extractor

- SHA256 del ZIP embebido y hash/tamaño de cada archivo, comprobados antes de escribir.
- Rechazo de rutas absolutas, traversal, nombres reservados de Windows, duplicados y symlinks del ZIP.
- Hasta 512 archivos, 4 MiB por archivo y 16 MiB de contenido total.
- Destino inexistente y padre existente; rechaza enlaces/junctions en la cadena de destino.
- Extracción en staging y publicación por movimiento de directorio, sin combinar árboles existentes.
- Limpieza solo del temporal propio cuando falla; nunca borra un proyecto anterior.
- `-ValidateOnly` sin escritura, `-WhatIf` sin creación y `-Launch` explícito para abrir el panel.
- Sin Internet, UAC, cambio de políticas, instalación de tareas ni modificaciones del Registro durante la extracción.

El hash embebido no sustituye Authenticode ni confianza en el origen del script entero. El autoextraíble no está firmado aquí. Las operaciones no constituyen un sandbox frente a código malicioso de la misma cuenta. Se recomienda extracción local en una carpeta controlada por el usuario.

## Primera función del roadmap: plugins

Se implementa **fase declarativa**, no host de código externo:

- Seis diagnósticos internos permitidos: 1, 14, 19, 27, 28 y 30.
- Esquema cerrado, límites de texto y tamaño, sin `command`, scripts, argumentos ni rutas ejecutables.
- Importación inactiva; activación confirmada ligada a ID y SHA256 del archivo.
- Relectura y verificación antes de ejecutar el diagnóstico mediante `Invoke-Tool`.
- Cambiar contenido invalida aprobación; rechazo de ID distinto al nombre de archivo.
- Modo solo lectura permite diagnósticos aprobados, pero impide cambiar almacén/aprobaciones.
- Auditoría de importación, estado, rechazos, solicitudes y errores.
- Dos ejemplos locales; no se cargan ni ejecutan automáticamente.
- Núcleo embebido en el PS1 principal y fuente independiente sincronizada mediante pruebas.

La clave local y las preferencias siguen siendo controles contra accidentes, no autenticación empresarial. No se afirma firma de plugins, identidad del editor, aislamiento, dependencia entre plugins, actualización automática ni host de código no confiable.

## Validación local

- **46 pruebas Python aprobadas** en este entorno, incluyendo: integridad del ZIP, índice, hashes, comparación byte a byte con todas las fuentes actuales, ausencia de recursión y límites.
- Regeneración reproducible en el mismo entorno Python/zlib, sin dependencias externas.
- Contratos estáticos: núcleo embebido, ejemplos/esquema, lista de diagnósticos, aprobación, modo solo lectura y ausencia de evaluación de comandos externos.
- **14 scripts PowerShell** comprobados con tree-sitter-powershell, sin errores detectados; comprobación de espacios de Git sin errores.

Se mantiene la suite Pester de 43 casos de la entrega anterior. Se añaden contratos nativos en `tests/Probar-Plugins.ps1` y pasos de CI para `-ValidateOnly`, `-WhatIf` y extracción temporal real.

**No ejecutado en este Linux:** extractor en Windows PowerShell, GUI/plugins interactivos, parser nativo, contratos PowerShell, Pester, CI remoto, EXE/MSI y firma real. Los controles locales no permiten afirmar que esas pruebas Windows hayan aprobado.

## Pendientes de esta fase

1. Ejecutar CI y extracción real en Windows 10/11, rutas con espacios/tildes, destino existente, permisos insuficientes, cancelación y limpieza tras fallo.
2. Probar importación/activación/ejecución/desactivación/retirada de plugins; corrupción, tamaño excesivo, enlaces e invalidación de aprobación.
3. Evaluar límites del número de plugins en el perfil y rendimiento de la lista con muchos archivos.
4. Mejorar accesibilidad del gestor y añadir pruebas de interacción/estado de foco.
5. Firmar la entrega en un entorno de construcción controlado y validar al editor por un canal de confianza.

## Resto del roadmap

i18n ES/EN/PT, dashboard gráfico, editor visual de temas, integración AD, workflows y ejecución aislada de plugins externos **siguen pendientes**. La implementación declarativa no se presenta como sustituto del host externo planificado. Ver `docs/ROADMAP-v4.0.0.md`.

## Regenerar después de cambios

```sh
python packaging/Build-Bootstrap.py
python -m unittest discover -s tests -v
```

Las pruebas comparan el autoextraíble con las fuentes actuales. Si editas un documento o script, regenera antes de compartir el único fichero.
