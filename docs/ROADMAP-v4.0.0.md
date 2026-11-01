# Hoja de ruta v4.0.0 · propuesta técnica

**Estado: inicio de desarrollo 4.0.0.** Se implementó una primera fase de plugins **declarativos** y un autoextraíble del proyecto completo. El host de código externo sigue **no implementado**. i18n ES/EN/PT, dashboard gráfico, editor visual de temas, AD y workflows permanecen planificados. No hay fecha comprometida ni se instalan dependencias de esas funciones al arrancar.

La primera fase se documenta en `Plugins/README.md`; los criterios siguientes describen el alcance futuro, no capacidades ya terminadas.

## Puerta de entrada: estabilizar 3.0.1

Antes de ampliar alcance:

- CI Windows y 43 casos Pester aprobados, con evidencia adjunta.
- Matriz manual de Windows 10/11, DPI, UAC, recuperación y Registro aprobada.
- EXE/MSI compilados, firmados y verificados; instalación/actualización/rollback/desinstalación probados.
- Resolver resultados integrados, cancelación compatible y estados fiables por operación.
- Instancia única o coordinación de operaciones; escrituras atómicas y pruebas de corrupción de estados.
- Revisión de permisos de auditoría, privacidad y titularidad/licencias de código heredado.

## 1. Plugins externos

### Propuesta

Contrato versionado `plugin.json` con `id`, versión, versión mínima de ATS, editor, punto de entrada, hash, firma y capacidades solicitadas. Directorios separados por usuario/equipo. Instalación y activación explícitas, sin descarga/ejecución al iniciar.

**No tratar un plugin PowerShell cargado en el proceso como un sandbox.** Tendría los privilegios completos del usuario. Preferir un host externo con cuenta restringida y protocolo IPC de operaciones permitidas; una lista declarativa de capacidades por sí sola no es una barrera de seguridad. Evitar elevar plugins de terceros.

### Aceptación

- Plugin firmado y editor aprobado; firma/hash inválidos bloquean carga.
- Contrato incompatible, timeout o crash no cierran el panel.
- Usuario puede desactivar/retirar plugin y ver permisos antes de aprobarlo.
- Acciones, editor y versión quedan auditados sin secretos.
- Pruebas de IPC, límites y entradas maliciosas; revisión de licencias.

## 2. Internacionalización (i18n)

Separar todas las etiquetas de UI en recursos **de datos**, con claves estables; español como idioma predeterminado y fallback. Inglés opcional en una primera fase. No evaluar código para cargar traducciones. Conservar UTF-8 con BOM en scripts para Windows PowerShell 5.1.

### Aceptación

- Ninguna etiqueta de la UI depende del idioma del sistema para identificar una acción.
- Fallback ante claves ausentes, formatos locales correctos y fechas de auditoría UTC invariantes.
- Teclado, lector de pantalla, alto contraste y DPI 100–200 % comprobados.
- Mensajes de herramientas externas claramente identificados como mensajes del sistema, sin prometer traducción perfecta de esos procesos.

## 3. Gráficas con LiveCharts

Evaluar **LiveCharts2** solo después de decidir el host. La aplicación actual usa Windows PowerShell 5.1/.NET Framework 4.8: **no asumir que una librería moderna .NET 8 puede cargarse en ese proceso**.

Opciones de evaluación:

1. Mantener 3.x en WPF/.NET Framework y usar gráficas simples compatibles, sin esa dependencia.
2. Migrar el host visual a .NET moderno/WPF y mantener operaciones PowerShell en workers con contrato claro.
3. Aplicación visual separada que recibe métricas por IPC.

### Aceptación

- Selección de versión/paquete compatible, licencia y dependencias revisadas y fijadas por hash.
- Historial acotado, frecuencia configurable, muestreo sin bloqueo y cierre limpio.
- Consumo medido durante una sesión larga y degradación a texto si falla la gráfica.
- Sin dependencias descargadas implícitamente al arrancar ni telemetría añadida sin consentimiento.

## 4. Integración con Active Directory

Módulo **opcional** disponible solo cuando existe el módulo RSAT `ActiveDirectory` y el usuario tiene conectividad y permisos. Fase inicial exclusivamente de consulta: usuario, grupo y equipo, con alcance del dominio explícito y resultados paginados.

No guardar contraseñas de dominio ni reutilizar la clave local de ATS como credencial. Preferir identidad integrada Windows; solicitudes adicionales mediante mecanismos aprobados. No consultar AD al iniciar ni enviar inventarios a servidores automáticamente.

### Aceptación

- Dominio ausente/RSAT no instalado: función deshabilitada con explicación, sin error global.
- Filtros y parámetros tipados, sin concatenación de filtros LDAP sin escape.
- Datos personales minimizados, exportación confirmada y auditoría sin tokens/contraseñas.
- Cualquier futura escritura exige permisos reales, vista previa, confirmación y pruebas en dominio de laboratorio.
- No incluir activación/desactivación masiva de cuentas como función predeterminada.

## 5. Workflows

Motor de pasos declarativos, no un editor para ejecutar código libre. Operaciones registradas por ID, parámetros tipados, dependencias (DAG), precondiciones, timeout, política de error y descripción de compensaciones cuando existan.

### Aceptación

- Vista previa y `WhatIf` real para cambios; confirmación antes de iniciar.
- Ciclos e IDs desconocidos rechazados; límites de pasos y tiempos.
- Reanudación segura y correlación por workflow/paso en logs.
- No afirmar rollback universal: conversión de disco, apagado y acciones externas pueden ser irreversibles.
- Cancelación solo mediante API compatible, sin matar procesos indiscriminadamente.
- Modo solo lectura bloquea cualquier paso de escritura antes de ejecutar el primer paso.

## Fases y resultados esperados

| Fase | Resultado | Condición para avanzar |
| --- | --- | --- |
| A | 3.0.1 estable y firmada | Pruebas, paquetes, recuperación y revisión de seguridad aprobados |
| B | Host/contratos e i18n | Prototipo medido, compatibilidad y migración decididas |
| C | Métricas gráficas y plugins limitados | Aislamiento, dependencias y recursos verificados |
| D | AD de solo consulta | Laboratorio y revisión de privacidad aprobados |
| E | Workflows de operaciones permitidas | Vista previa, cancelación, auditoría y recuperación probadas |

## Política de migración

Versionar esquemas de preferencias, plugins y workflows. Copia previa antes de migrar, rechazo de esquemas desconocidos, sin convertir silenciosamente operaciones en tareas elevadas. Mantener informes/logs y documentar cambios incompatibles. No romper ni reemplazar 3.x sin una ruta de regreso probada.

## Fuera de alcance por defecto

Desactivar protecciones para evitar avisos, guardar credenciales en JSON, ejecutar plugins descargados sin revisión, elevar toda la aplicación, escanear redes/dominios automáticamente o prometer un sandbox con simples filtros de texto.
