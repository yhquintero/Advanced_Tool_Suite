# Política de seguridad

## Estado y versiones

NEXUS 4.0.0 es un inicio de desarrollo. No hay una versión certificada ni un SLA de respuesta. Las ramas antiguas y el BAT heredado no reciben una promesa de soporte de seguridad. Los mantenedores evalúan reportes sobre el código actual de `main` y revisiones concretas de PR; identifica siempre commit, versión, Windows y PowerShell.

**Ningún control proporciona seguridad completa.** Las pruebas unitarias, CI, SHA256 y la licencia MIT no son auditorías profesionales ni garantías de funcionamiento seguro.

## Comunicar una vulnerabilidad de forma responsable

1. Si GitHub muestra **Security → Report a vulnerability**, usa ese canal privado. Su habilitación está pendiente de permisos del propietario; no se afirma que esté disponible.
2. Si no existe, abre únicamente una incidencia neutra solicitando un canal privado de contacto al mantenedor. No incluyas detalles explotables, PoC, datos personales o credenciales en esa incidencia.
3. Tras disponer de un canal privado, aporta commit afectado, impacto, requisitos de explotación, reproducción mínima y propuesta de mitigación. No hace falta explotar equipos de terceros ni producir daños.
4. Acuerda divulgación y corrección con el mantenedor. No se promete plazo de respuesta, recompensa ni clasificación CVE.

Nunca adjuntes PFX, claves privadas, contraseñas, tokens, logs de dominio completos, inventarios sin anonimizar o archivos de producción. No publiques información de vulnerabilidades en plantillas de fallo normal.

## Modelo de confianza

- La aplicación ejecuta operaciones locales con los permisos de su usuario y, cuando se confirma, mediante UAC por acción.
- Inicia el panel como usuario estándar. No lo ejecutes globalmente como administrador para evitar avisos.
- Solo lectura, clave local y DPAPI protegen contra accidentes/exposición de estado local; no restringen a la propia cuenta, administradores ni malware bajo esa identidad.
- Plugins v1 son datos declarativos de diagnósticos permitidos. No existe sandbox para scripts externos ni autenticación de editor. Cambiar un archivo invalida su aprobación por hash; modificar preferencias sigue estando al alcance de la cuenta local.
- Hashes/recibos detectan incoherencias y archivos modificados; un atacante que sustituya script y hashes puede recalcularlos. Verifica origen y firma por un canal confiable.
- El autoextraíble incluido no está firmado aquí. No uses `iex`, ejecución de descargas opacas ni desactivación de políticas como instalación recomendada.

## Riesgos operativos conocidos

- Conversión NTFS irreversible desde esta suite, apagado/reinicio inmediato tras confirmar, restablecimiento de red y cambios de firewall pueden causar pérdida de disponibilidad o protección.
- Deshacer solo cubre un valor interno; no revierte modificaciones externas ni toda una operación.
- Puntos de restauración pueden fallar o estar limitados por Windows. No sustituyen una copia de datos.
- Herramientas en procesos externos pueden continuar tras cerrar el panel; `DISPATCHED` no acredita éxito.
- Instalación, actualización, extracción y rollback no son transacciones resistentes a un proceso malicioso del mismo usuario. Usa carpetas propias, evita ubicaciones compartidas y cierra la aplicación antes de actualizar.
- Inventarios y auditoría contienen datos del equipo/red/usuario. Los logs no son inmutables, no se cifran de forma general ni se envían a un colector. No cambies ACL de `C:\REPORTE` para dar acceso amplio a terceros.
- El `.bat` histórico mantiene sus riesgos originales y no debe usarse como sustituto seguro de la nueva UI.

## Repositorio, CI y web

Los workflows versionados usan `contents: read` por defecto, acciones fijadas por commit y ningún `pull_request_target`. Las PR no reciben certificados ni secretos de firma. Los permisos de Pages solo se conceden al job de despliegue manual desde `main`; deben revisarse junto con la protección del entorno.

La web estática no recibe formularios ni usa JavaScript/cookies/analítica. Su CSP por meta limita recursos, pero **no sustituye cabeceras HTTP del servidor**. GitHub Pages controla TLS y cabeceras; no se afirma configurar HSTS, protección WAF, `frame-ancestors` o rate limiting desde HTML.

Alertas, reporte privado, reglas de rama, permisos globales de Actions y publicación Pages requieren permisos del propietario. La conexión utilizada devolvió 403 en ajustes administrativos: consulta [la lista verificable de pendientes](docs/SEGURIDAD-REPOSITORIO.md).

## Antes de publicar una distribución

Completa la matriz Windows, revisa licencias y dependencias, verifica firmas y editor, valida hashes y extracción, prueba actualización/desinstalación/recuperación, revisa logs sensibles y conserva resultados de CI. No publiques secretos de firma ni anuncies controles como activos sin verificarlos en GitHub.
