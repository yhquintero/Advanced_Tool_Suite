# Revisión detallada · Advanced Tool Suite 3.0.0

Fecha: **2026-11-01**. Revisión de código y recursos realizada en Linux; no equivale a una certificación ni a una prueba de Windows. Se han preparado las 20 áreas solicitadas; EXE y MSI son recetas de construcción, no binarios verificados.

## 1. Cobertura y trazabilidad

| Área | Implementación | Evidencia local | Pendiente en Windows |
| --- | --- | --- | --- |
| 1. Animación de entrada | Opacidad + desplazamiento, tarjetas y navegación | Funciones y recursos revisados; análisis sintáctico | Fluidez, foco, preferencia del sistema y movimiento reducido |
| 2. SVG por herramienta | 42 geometrías distintas embebidas y fuentes SVG | Prueba de correspondencia exacta y XML de los SVG | Rasterizado WPF, proporciones y DPI |
| 3. Temas | Cuatro paletas y recursos dinámicos | Prueba de presencia y persistencia revisada | Cambio repetido de tema, contraste y recursos WPF |
| 4. Compacto | Barra de 410 px, selector de categoría y regreso | Código y controles revisados | 100–200 % DPI y redimensionado |
| 5. Fondo | Gradiente animado, sin partículas | Animación desactivable revisada | Coste real GPU/CPU y sesiones remotas |
| 6. Búsqueda | Nombre, descripción y categoría, filtro combinado | Catálogo y controles XML comprobados | Escritura rápida, teclado y lectura de pantalla |
| 7. Favoritos | Persistencia validada y estrellas independientes de la tarjeta | Prueba que evita botones anidados | Mantener favoritos tras reiniciar, foco al filtrar |
| 8. Historial | Exporta actividad actual y cinco rotaciones | Contrato de rotación preparado | Exportación con archivos en uso y permisos insuficientes |
| 9. Tareas | Informes únicos limitados, sin credenciales | Contrato estático de principal y acción | Fecha futura, sesión cerrada, resultado y eliminación |
| 10. Preflight | Dependencias, unidad, FAT32, espacio y medio conocido | Código revisado, entradas limitadas | HDD/SSD/USB/RAID, permisos y volúmenes virtuales |
| 11. Métricas | Runspace único, consultas CIM y temporizador | Ciclo de vida revisado | Exactitud, indisponibilidad y consumo en sesión prolongada |
| 12. Deshacer | Un valor/tipo anterior, ruta por lista blanca | Pruebas de lista blanca preparadas | Ausencia previa, tipo, cambios externos y restauración exacta |
| 13. Auditoría | UTC, sesión, usuario, versión, ID y estado; copia secundaria | Contrato de estructura y retención | Concurrencia, disco lleno, ACL y directorios compartidos |
| 14. Solo lectura | Lista blanca conservadora y controles secundarios | Lista exacta comprobada | Recorrer todos los botones, incluida salida de modo |
| 15. Clave | PasswordBox, PBKDF2/SHA256, DPAPI y bloqueo | Primitivas y limpieza del BSTR comprobadas | Coincidencia, cancelación, bloqueo, reinicio y corrupción |
| 16. Restauración | Proceso UAC asíncrono, verificación de punto nuevo | Condición de éxito/fracaso comprobada | Protección apagada, límite 24 h, espacio, UAC cancelado |
| 17. EXE | ps2exe con STA, x64, icono, sin consola principal | Receta y parámetros revisados | Construcción, ejecución, firma y antivirus |
| 18. MSI | WiX 3.x, por usuario, icono y actualización mayor | XML válido y alcance comprobado | Compilación, ICE, instalación/upgrade/desinstalación |
| 19. Portable | Un PS1 sin carga de archivos auxiliares | Recursos embebidos y ausencia de placeholders comprobados | Copia a carpeta nueva, espacios, caracteres Unicode |
| 20. Explorador | HKCU, instalación y retirada explícitas | Rutas entrecomilladas revisadas | Windows 10/11, clic derecho, ruta movida y retirada |

## 2. Resultados obtenidos en este entorno

- **21 pruebas Python aprobadas** mediante `python -m unittest discover -s tests -v`.
- Los dos bloques XAML son XML bien formado y no repiten nombres de controles dentro de su ventana.
- Las 42 herramientas tienen ID único y despacho implementado.
- Las 42 fuentes SVG corresponden exactamente a las geometrías embebidas y son distintas.
- Los cuatro archivos `.ps1` pasan el análisis sintáctico adicional con **tree-sitter-powershell**. Este analizador no es el motor oficial de Windows PowerShell.
- `git diff --check` sin errores de espacios.
- Se prepararon un validador con el parser nativo de PowerShell, pruebas de contratos de funciones y un smoke test WPF.
- Se preparó CI para ejecutar Python en Linux y las comprobaciones Windows PowerShell/WPF en Windows. **No se ha ejecutado remotamente en esta sesión.**

**No ejecutado aquí:** parser nativo de Windows PowerShell, creación real de controles WPF, interacciones de GUI, UAC, Defender, CHKDSK, conversión de volúmenes, tareas, Registro real, puntos de restauración, ps2exe, WiX, instalación, desinstalación ni SmartScreen. La prueba de XML no demuestra que todas las propiedades WPF sean correctas en ejecución.

## 3. Correcciones realizadas durante la revisión

1. Se evitan botones de favoritos anidados en el botón principal: son controles hermanos, con evento independiente.
2. Los recursos de tema se reemplazan/clonan para evitar modificar brushes congelados por WPF.
3. En compacto se conserva un selector de categorías; no se pierde acceso a herramientas por ocultar la navegación.
4. Los ejecutables del sistema se resuelven desde sus directorios de Windows. Explorer y Regedit se buscan en `%SystemRoot%`, no por error en System32.
5. La comprobación del medio usa un número de serie conocido; no equipara indiscriminadamente el número de disco con un DeviceId físico.
6. Se comprueba que Checkpoint-Computer haya creado un punto nuevo; una advertencia no se trata como éxito.
7. Restaurar el menú moderno no borra toda la rama CLSID ni valores ajenos. Se bloquea si la clave contiene otros ajustes.
8. Deshacer usa rutas permitidas, guarda ausencia y tipo, y rechaza cambios posteriores detectados.
9. Las preferencias persistidas aceptan booleanos reales y favoritos numéricos válidos, no datos arbitrarios.
10. Las consolas devuelven un código; sus temporizadores se retiran al finalizar para no acumular observadores.
11. Solicitud, envío y fin de proceso se registran por separado; no se presenta iniciar una herramienta como trabajo completado.
12. El EXE/MSI no se etiqueta como independiente de PowerShell ni se eleva todo el panel al compilarlo.
13. El modo solo lectura no abre terminales, Regedit ni paneles de administración que permitan modificar el equipo.

## 4. Limitaciones y riesgos residuales

### Alta prioridad antes de distribuir

- **Validación real Windows pendiente.** Debe aprobarse la lista de `PRUEBAS-WINDOWS.md`, especialmente WPF, restauración y empaquetado. No usar conversiones ni apagados como pruebas sobre un equipo de producción.
- **No hay firma de código ni de paquetes.** Los hashes detectan cambios respecto a un manifiesto confiable, pero no acreditan autoría. Firmar script, ejecutable y MSI con un certificado adecuado y sello de tiempo antes de distribuir.
- **No hay auditoría inmutable.** Tanto logs locales como la carpeta C:\REPORTE son modificables por quienes tengan permisos. No se endurecen ACL existentes ni se implementa un servicio privilegiado de auditoría. El panel continúa si falla el registro, avisando: no cumple un modelo fail-closed de cumplimiento normativo.
- **Clave y solo lectura no son límites de privilegios.** Un usuario con acceso al archivo o a su perfil puede modificar/restablecerlos. Para restricciones de técnicos: cuentas limitadas, AppLocker/WDAC, políticas y un backend con autorización real.

### Prioridad media

- **Operaciones externas:** no existe progreso integrado ni cancelación segura general. El registro de un proceso no demuestra por sí solo el estado final del equipo. Cerrar la suite deja los procesos externos en ejecución.
- **Undo de un solo nivel:** no revierte cambios externos ni conserva todo el árbol del Registro. No es una transacción; un cierre entre guardar la copia y escribir el valor requiere revisión manual.
- **Límite de restauración:** Windows puede impedir crear otro punto durante 24 horas. No se debilita esta protección. No recupera archivos personales, cambios de red de terceros o una conversión NTFS.
- **Instancias concurrentes:** hay reintentos breves en logs, pero no bloqueo global de todas las operaciones ni coordinación transaccional de rotación/preferencias. Recomendado usar una sola instancia hasta probar concurrencia.
- **Integración y tareas:** son opt-in, por usuario y no se eliminan automáticamente al mover un portable. Retirar entrada y tareas explícitamente; el MSI conserva informes/preferencias/logs.
- **Diagnóstico de disco:** el medio puede ser indeterminado si no hay número de serie único o existen capas virtuales. La salud reportada por Windows no es una comprobación SMART exhaustiva.

### Mejoras de experiencia pendientes

- Español completo con tildes en todos los textos internos heredados y traducción de mensajes del sistema cuando sea viable.
- Mejorar accesibilidad con lector de pantalla, alto contraste, teclas de acceso y escalado al 200 %.
- Evitar reconstruir todas las tarjetas en cada pulsación; añadir debounce y restauración de foco si aparecen problemas reales de fluidez.
- Evaluar contraste de las cuatro paletas con herramientas WCAG y pruebas humanas.
- Sustituir asistentes sencillos por formularios con validación en línea, selección de volúmenes y gestión de tareas creadas.

## 5. Plan de perfeccionamiento recomendado

1. **3.0.1 — Estabilización Windows:** ejecutar CI y matriz de VM; corregir hallazgos, registrar versiones exactas de Windows/.NET y resultados por prueba.
2. **3.1 — Resultados integrados:** runspaces por operación, progreso real, estados tipados, tiempos máximos y cancelación cuando la API lo permita; nada de matar procesos indiscriminadamente.
3. **3.2 — Seguridad operativa:** instancia única o mutex, escrituras atómicas de todos los estados, detección de corrupción, permisos documentados y colector de auditoría externo opcional.
4. **3.3 — Administración avanzada:** historial de deshacer por operación con resolución de conflictos, navegador de tareas ATS y gestión de informes con límites de retención.
5. **Distribución estable:** construir en entorno limpio, fijar versiones/hashes de dependencias, firmar, probar actualización/desinstalación y publicar paquetes solo después de aprobar la matriz.

## 6. Criterio de aceptación

Se podrá etiquetar **validada para distribución** cuando exista evidencia de CI Windows aprobada, matriz manual aprobada en Windows 10/11, paquetes compilados y verificados, pruebas de recuperación/actualización y documentación de riesgos aceptados. Hasta entonces: versión preparada para prueba, no certificada para producción.
