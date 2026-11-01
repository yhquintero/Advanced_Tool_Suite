# Contribuir a Advanced Tool Suite

Gracias por colaborar. La documentación y la experiencia principal se mantienen en español.

## Preparar una propuesta

1. Describe un problema normal en Issues sin datos privados. Para vulnerabilidades sigue [SECURITY.md](SECURITY.md), no una incidencia pública con PoC.
2. Trabaja en una rama y abre una PR pequeña con contexto, riesgos, pruebas y capturas solo si proceden de una ejecución real. No presentes diseños como capturas reales.
3. No subas inventarios, registros, PFX, claves, credenciales, datos de dominio ni artefactos personales.
4. No añadas descargas/ejecución automáticas, elevación global, parámetros arbitrarios de borrado o desactivación de antivirus/políticas.

## Pruebas requeridas

```sh
python packaging/Check-Repository.py
python packaging/Build-Bootstrap.py
python -m unittest discover -s tests -v
```

En Windows ejecuta los contratos, Pester y smoke test descritos en [BUILD.md](BUILD.md). Explica qué pruebas **no** has ejecutado. Modificaciones administrativas requieren VM con instantánea; no se prueban sobre sistemas de terceros ni equipos de producción.

El `.ps1` principal sigue siendo autónomo. Si editas `Plugins/Plugin.Core.ps1`, sincroniza su bloque embebido. Regenera el autoextraíble después de modificar cualquiera de sus fuentes, incluida documentación, web y políticas.

## Revisión de seguridad

- Valida datos con listas permitidas y límites, no mediante evaluación de código.
- Conserva rutas seguras, protección frente a enlaces y comprobaciones de no sobrescritura.
- Respeta `ShouldProcess` y confirma efectos irreversibles. No afirmes rollback universal.
- En CI fija acciones por SHA completo; revisa las actualizaciones de Dependabot y los permisos añadidos.
- No uses `pull_request_target` para ejecutar código de contribuyentes ni introduzcas secretos en pruebas.
- Cambios web deben funcionar sin scripts, formularios, dependencias remotas ni datos sensibles.

## Licencias y atribución

Aporta únicamente código y recursos que tengas derecho a distribuir. Las contribuciones se proponen bajo MIT salvo acuerdo explícito del proyecto. Incluye atribución/licencia de terceros cuando corresponda y no elimines avisos del código heredado sin autorización. La autoría y derechos del material histórico deben confirmarse antes de una publicación estable.

## Antes de solicitar revisión

Actualiza manual/CHANGELOG si cambia el comportamiento, comprueba enlaces relativos y añade pruebas de regresión. La revisión de CODEOWNERS es una ayuda de organización; no obliga a aprobar sin una regla de protección configurada en GitHub.
