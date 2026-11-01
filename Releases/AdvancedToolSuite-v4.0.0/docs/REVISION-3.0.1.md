# Revisión de entrega 3.0.1

Fecha: **2026-11-01**. Amplía la revisión de 3.0; no sustituye la matriz de pruebas real de Windows.

## Cinco entregables solicitados

| Punto | Archivos | Estado real |
| --- | --- | --- |
| 1. EXE, manifiesto y Authenticode | `packaging/Build-Release.ps1`, `manifest.xml`, `Sign-Release.ps1`, `BUILD.md` | Receta implementada; EXE no compilado ni firmado aquí |
| 2. Instalación y retirada | `install.ps1`, `uninstall.ps1`, `packaging/Deployment.Common.ps1` | Código preparado; instalación real/rollback pendientes en Windows |
| 3. Pester 43 casos | `tests/ATS.Tests.ps1`, `tests/Run-Pester.ps1`, CI Windows | 43 casos definidos y contados estáticamente; no ejecutados en este entorno |
| 4. Documentación | `MANUAL.md`, `BUILD.md`, `CHANGELOG.md`, `LICENSE`, `VERSION.json` | Escrita y coherencia de archivos/versiones comprobada |
| 5. Roadmap v4 | `docs/ROADMAP-v4.0.0.md` | Plan técnico; plugins/i18n/LiveCharts/AD/workflows no implementados |

Se mantiene el directorio `tests` ya existente. En Windows, `Tests\ATS.Tests.ps1` y `tests\ATS.Tests.ps1` resuelven al mismo archivo; no se crean dos directorios que colisionen por mayúsculas al clonar en Windows.

## Validación realizada localmente

- **34 pruebas Python aprobadas**, incluyendo las 21 previas y 13 de distribución.
- Verificado que Pester contiene exactamente **43 casos numerados**, sin omisiones declaradas.
- **10 archivos PowerShell** sin errores detectados por tree-sitter-powershell.
- XML de manifiesto y WiX válido; manifiesto `asInvoker`, `uiAccess=false`, versión alineada.
- Contratos de orden de construcción: incrustación antes de firma, hashes después de firma.
- Contratos de instalación: ShouldProcess, lista blanca de archivos, comprobación de hashes y revalidación de staging.
- `git diff --check` sin errores.

Esto **no demuestra** ejecución satisfactoria de los 43 casos Pester ni validación nativa PowerShell/WPF. El parser de tree-sitter es un control adicional, no el motor oficial de PowerShell. No se ejecutó CI remotamente ni se usó un certificado real.

## Decisiones y mejoras de seguridad

1. El manifiesto se incrusta con `mt.exe` de Windows SDK, sin inventar un parámetro `-manifest` para ps2exe.
2. El constructor no eleva el panel, no importa PFX y no guarda secretos. Firma solo con un certificado existente, vigente y con uso de firma de código.
3. Se verifica firma y presencia de sello; una operación parcialmente firmada falla, no se presenta como exitosa.
4. Las salidas no vacías se rechazan; se evita mezclar artefactos de una compilación previa con hashes nuevos.
5. Instalación por usuario en ruta fija; no existe parámetro de destino arbitrario ni se escribe registro HKLM.
6. No se borra una carpeta desconocida sin recibo; la retirada se basa en nombres permitidos y hashes, no en rutas recibidas de JSON.
7. Se rechazan junctions/symlinks de la cadena del destino y archivos gestionados enlazados.
8. El paquete se comprueba antes y después de copiar a staging. La actualización rechaza downgrade y archivos ajenos/modificados.
9. Se intenta rollback de la carpeta y del registro/acceso directo; una recuperación fallida puede necesitar intervención manual y debe conservar el backup.
10. Desinstalación por scripts conserva datos y solo retira enlaces/contexto que apunten a la copia gestionada.
11. MSI e instalación por scripts son métodos separados. El MSI bloquea coexistencia con la entrada registrada por scripts; los scripts rechazan el formato Msi.
12. Los 43 casos Pester usan funciones puras y temporales para recibos/logs; no lanzan acciones administrativas ni modifican Registro, firewall o tareas.

## Pruebas adicionales pendientes de Windows

- Parser oficial de los 10 scripts, Pester 5.7.1 con 43/43 y smoke WPF.
- Instalación nueva estándar, actualización a versión superior, rechazo de downgrade y `-WhatIf` sin cambios.
- Rechazo de paquete incompleto, hash incorrecto, recibo ajeno, ruta enlazada y acceso directo modificado.
- Fallo al guardar acceso directo/registro, rollback y recuperación con archivos abiertos.
- Desinstalación desde Windows y consola, confirmación/cancelación, archivo cambiado, archivos ajenos y enlace de otra copia.
- Compilación real con ps2exe 1.0.17, extracción/verificación de todos los campos del manifiesto y prueba del DPI.
- Certificado real de firma y sello; rechazo por falta de EKU, expiración, cadena no confiable, servidor inaccesible y modificación posterior.
- MSI: validadores ICE, instalación, actualización, retirada y bloqueo de mezcla de métodos.
- SmartScreen/Defender en VM limpia sin desactivar sus protecciones.

## Riesgos que no se declaran resueltos

- **Hashes y recibos no están firmados.** Son controles de integridad/propiedad operativa, no autenticación contra quien reemplace todo el paquete. Verificar origen antes de ejecutar instaladores.
- `-RequireSignature` exige confianza del sistema, no fija el editor permitido. Revisar identidad del firmante y considerar pinning empresarial en una siguiente versión.
- Validación y operaciones de archivos no son una transacción de seguridad frente a otro proceso malicioso del mismo usuario; hay ventanas de carrera. No ejecutar desde carpetas compartidas no confiables ni con elevación global.
- El rollback es de mejor esfuerzo; permisos cambiados, bloqueo de archivos o interrupción del equipo pueden impedirlo.
- No se automatiza recuperación de una instalación sin recibo o modificada. Se bloquea antes de borrar y se requiere revisión, para evitar pérdida de datos.
- Logs editables y sin garantías de auditoría completa; no se implementa control de acceso real con la clave local.
- La licencia MIT en español requiere que los mantenedores confirmen derechos sobre contribuciones heredadas antes de distribuir. No altera licencias de terceros.

## Próxima prioridad recomendada

Ejecutar CI y la matriz Windows, corregir hallazgos y registrar evidencia antes de publicar. Después: firma de paquetes en un entorno controlado, pinning opcional de editor, prueba de rollback con inyección de fallos y resultados integrados en la GUI. El roadmap v4 se aborda solo tras esa estabilización.
