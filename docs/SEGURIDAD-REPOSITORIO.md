# Presentación web y endurecimiento del repositorio

Revisión: **2026-11-01**. Todo estado debe verificarse antes de anunciarlo. No se garantiza seguridad completa.

## Qué está preparado en esta rama

- README reorganizado con navegación, inicio rápido, alcance y límites, sin insignias que afirmen una validación inexistente.
- LICENSE MIT canónica para identificación automática y traducción española separada, sin cambiar las condiciones MIT.
- SECURITY, CONTRIBUTING, avisos de terceros, plantillas de Issues/PR y CODEOWNERS.
- Acciones de CI fijadas por SHA completo, credenciales de checkout no persistidas, permisos mínimos, tiempos máximos y concurrencia.
- Dependabot semanal para revisar actualizaciones de acciones; no es un escáner PowerShell ni garantiza correcciones automáticas.
- Comprobación local de enlaces, referencias a acciones, metadatos, patrones básicos de secretos y web estática sin código activo.
- Web responsive `site/`, sin formularios, JavaScript, analítica, cookies propias, fuentes remotas o recursos de terceros.
- Despliegue de Pages solo manual desde main, con permisos de publicación/OIDC limitados al job de deploy.

Estos archivos solo tendrán efecto en la página pública/configuración de colaboración cuando se incorporen a la rama predeterminada. CODEOWNERS no impone revisión obligatoria por sí solo.

## Cambios administrativos: bloqueados por permisos

La conexión utilizada devolvió **HTTP 403 · Resource not accessible by integration** al editar metadatos, leer protección de main/permisos globales de Actions y habilitar alertas/reporte privado. No es correcto afirmar que se activaron. El permiso `admin` mostrado en datos generales no garantiza que la integración tenga los permisos específicos de cada endpoint.

La consulta de Pages devolvió 404: no se confirmó una web publicada. No se reemplazó el Website con una URL de Pages no verificada. No se han cambiado la protección de rama ni los permisos globales.

El propietario debe revisar los permisos de la conexión de GitHub en Arena o aplicar los ajustes desde GitHub. No hacen falta claves, tokens, contraseñas ni códigos 2FA en chat.

## About: listo para copiar (255 de 350 caracteres)

> Suite de herramientas para Windows 10/11 en PowerShell: panel WPF en español, diagnósticos, plugins declarativos y distribución autoextraíble. Proyecto en desarrollo con documentación, pruebas y controles de seguridad; sin promesas de protección absoluta.

**Quedan 95 caracteres.** El texto se valida desde `.github/repository.json`.

- Website provisional real: `https://github.com/yhquintero/Advanced_Tool_Suite#readme`
- Topics: `powershell`, `windows`, `wpf`, `system-administration`, `diagnostics`, `security`, `spanish`, `portable`, `plugins`.

En GitHub: engranaje de **About** en la página del repositorio. Alternativamente, con GitHub CLI autorizado por el propietario:

```powershell
.\packaging\Configure-Repository.ps1
.\packaging\Configure-Repository.ps1 -Apply -WhatIf
.\packaging\Configure-Repository.ps1 -Apply
```

El script no cambia seguridad global ni sustituye topics existentes; agrega los propuestos. Comprueba la respuesta real y el About visible antes de marcarlo como aplicado.

## Lista de configuración para el propietario

### Protección de main / Rulesets

- [ ] Exigir PR antes de incorporar cambios, revisión al menos por un mantenedor y CODEOWNERS cuando proceda.
- [ ] Descartar aprobaciones al cambiar código, exigir resolver conversaciones y bloquear force-push/borrado.
- [ ] Exigir los checks CI Linux y Windows por sus nombres reales tras una ejecución satisfactoria. No inventar checks que puedan bloquear indefinidamente.
- [ ] Revisar bypasses para recuperación; no impedir accidentalmente la administración del repositorio.

### Seguridad de código

- [ ] Habilitar Dependency graph/Dependabot alerts donde esté disponible.
- [ ] Revisar Dependabot security updates y la cobertura real de cada ecosistema; no todos los scripts tienen dependencias analizables.
- [ ] Habilitar secret scanning y push protection si el repositorio/plan lo permite.
- [ ] Habilitar private vulnerability reporting; verificar el botón Report a vulnerability.
- [ ] No afirmar que CodeQL audita PowerShell: seleccionar analizadores compatibles y comprobar sus límites.
- [ ] Activar 2FA en cuentas de mantenedores y mínimo privilegio en apps instaladas, sin compartir credenciales.

### GitHub Actions

- [ ] Workflow permissions: **Read repository contents and packages** por defecto.
- [ ] Desactivar **Allow GitHub Actions to create and approve pull requests** salvo necesidad revisada.
- [ ] Limitar acciones permitidas a las revisadas y fijarlas por SHA; revisar PRs de actualización.
- [ ] Aprobación de workflows de colaboradores externos y revisión antes de ejecutar cambios.
- [ ] Certificados y firma solo en entorno protegido, con autorización manual y sin exponerlos a PRs.

## Publicar la web de forma controlada

1. Revisar/validar `site/` y el workflow `pages.yml`, e incorporar a main mediante PR.
2. Settings → Pages → Source: **GitHub Actions** (requiere permisos del propietario).
3. Proteger el entorno `github-pages` para main y revisores autorizados según las posibilidades del plan.
4. Ejecutar manualmente **Publicacion manual de la web** desde main.
5. Verificar el despliegue, URL, rutas, HTTPS, certificado y accesibilidad en navegador.
6. Solo entonces actualizar el Website de About a la URL real publicada. El script propuesto actualmente limita el destino al README para evitar anunciar una URL inexistente; revisarlo conscientemente al publicar.

El workflow no activa Pages por sí solo y no despliega PRs. No hace falta un servidor Node ni un proceso con acceso al equipo del visitante. Sus enlaces a documentación apuntan a GitHub main; hay que incorporar los documentos antes de comprobarlos públicamente.

### Cabeceras y límites del hosting

La CSP por meta restringe scripts, conexiones y recursos. Una meta no aplica `frame-ancestors`, HSTS, `X-Content-Type-Options` ni otras cabeceras de respuesta. GitHub Pages controla TLS/cabeceras y puede tener sus propios registros/cookies de plataforma. No se pueden prometer cambios de esos controles editando HTML.

Si se requiere política de cabeceras propia, usar un hosting/proxy administrado con HTTPS, CSP por cabecera, `frame-ancestors`, HSTS tras revisar subdominios, `nosniff`, permisos y caché revisados. No agregar archivos `_headers` fingiendo que GitHub Pages los interpreta.

## Pruebas y mantenimiento

```sh
python packaging/Check-Repository.py
python packaging/Build-Bootstrap.py
python -m unittest discover -s tests -v
```

El checker no usa red ni valida si un enlace externo responde. Detecta patrones limitados de secretos, no todos los formatos ni datos codificados. Las pruebas no certifican ausencia de vulnerabilidades. Tras cambiar fuentes/políticas/web, regenera el autoextraíble para no entregar documentación obsoleta.

La licencia canónica está en inglés por interoperabilidad; la documentación y su traducción permanecen en español. Confirma titularidad y atribuciones heredadas antes de publicar. La licencia no es una garantía de seguridad.

## Resultado local de esta revisión

- **59 pruebas Python aprobadas**, incluyendo 13 contratos nuevos de repositorio/web.
- Checker de enlaces, web pasiva, About, acciones fijadas y patrones básicos de secretos aprobado.
- Autoextraíble regenerado con los archivos de políticas y presentación web.
- Vista previa HTTP local iniciada para revisar la web; no equivale a un despliegue en GitHub Pages.
- Configuración administrativa remota sigue pendiente por HTTP 403. La existencia de una PR no activa esos controles.
- La ejecución Windows, Pester y la publicación/firma permanecen pendientes; se mantiene su matriz separada.
