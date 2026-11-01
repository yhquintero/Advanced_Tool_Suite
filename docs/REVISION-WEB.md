# Revisión del rediseño web NEXUS

Fecha: 2026-11-01. Estado: preparado para revisión; **no se afirma publicación en GitHub Pages**.

## Alcance y criterio

Se tomó `yhquintero/inventario` como referencia de organización (presentación, módulos, inicio, documentación y preguntas), no como fuente de código o activos. NovaGest declara una licencia propietaria. Esta implementación conserva la identidad NEXUS y usa HTML/CSS originales y el logo local existente.

Esta es una web documental. No administra Windows, no tiene backend ni muestra mediciones del visitante. El panel del hero es una ilustración CSS, no una captura ni una demostración fiel de la interfaz WPF.

## Revisión de 20 puntos

| Paso | Mejora realizada | Comprobación / límite |
| --- | --- | --- |
| 01 | Referencia respetada sin copiar recursos propietarios | Organización comparable, implementación e identidad propias |
| 02 | Identidad visual índigo, lavanda y menta | Variables CSS, logo local y tipografía del sistema |
| 03 | Portada con mensaje y contexto de Windows | Requisitos y aviso de ejecución local visibles |
| 04 | Ilustración original del panel | Etiquetada como conceptual; sin mediciones reales |
| 05 | Acciones de inicio y acceso al código | Enlaces reales; sin botones de ejecución ficticios |
| 06 | Resumen con datos del producto | 42 herramientas y 6 categorías reales; «Todas» no cuenta como categoría |
| 07 | Seis bloques de funciones | Enlaces a catálogo, manual, plugins e historial |
| 08 | Separación web / aplicación / fuentes | No se presenta una aplicación web de administración |
| 09 | Catálogo nativo desplegable | 42 IDs, nombres, descripciones y permisos tomados del PS1 |
| 10 | Generación reproducible del catálogo | Python estándar; no evalúa PowerShell; falla si cambia el contrato de IDs |
| 11 | Guía local de primera ejecución | `-ValidateOnly`, extracción sin apertura y simulación `-WhatIf` |
| 12 | Requisitos y política de ejecución | Sin instrucciones de bypass o desactivación de protecciones |
| 13 | Página de seguridad y privacidad | UAC, datos locales, plugins, límites de hashes y restauración |
| 14 | Estado de v4 transparente | Desarrollo y validaciones pendientes separados del roadmap |
| 15 | Preguntas frecuentes y documentación | Acordeones HTML nativos y enlaces verificables |
| 16 | Diseño adaptable y temas del sistema | Reglas para móvil/tableta/escritorio, claro/oscuro e impresión |
| 17 | Accesibilidad de base | Idioma, un H1 por página, foco visible, salto a contenido y movimiento reducido |
| 18 | Superficie web pasiva | CSP por meta, sin JavaScript, formularios, fuentes remotas o analítica |
| 19 | Prevención de regresiones | Pruebas de anclas, IDs únicos, fuentes y sincronización; control antes de Pages |
| 20 | Historia y distribución actualizadas | CHANGELOG, README, esta revisión y autoextraíble regenerado |

## Validación realizada

- **69 pruebas Python** de repositorio, distribución y contratos; incluyen 10 nuevas pruebas de la web/catálogo.
- `python packaging/Build-Site-Catalog.py --check`: catálogo sincronizado con el origen.
- `python packaging/Check-Repository.py`: recursos/enlaces locales, HTML pasivo, referencias de acciones y patrones básicos de secretos. No es una auditoría integral.
- Comprobación de navegador con **Chromium 153 y Playwright Core** en Linux: inicio, guía y seguridad en anchos **320, 390, 768, 1024 y 1440 px**. Sin desbordamiento horizontal, errores de página/consola ni peticiones de recursos remotos. Apertura y cierre de categorías y preguntas comprobados.
- **axe-core** con etiquetas WCAG 2 A/AA y 2.1 AA: cero infracciones automáticas detectadas en las tres páginas, en claro y oscuro a 1440 px. Se corrigió el contraste de una etiqueta del tema claro durante la revisión. Esto no certifica conformidad WCAG ni sustituye pruebas con lectores de pantalla y usuarios.
- Capturas de escritorio, móvil y tema claro inspeccionadas; herramientas de navegador instaladas solo en un directorio temporal fuera del repositorio. No se añaden dependencias Node al producto ni al autoextraíble.
- Los enlaces GitHub `blob/main` y `tree/main` se comparan con archivos locales existentes; no se afirma haber validado respuestas HTTP de todos los enlaces externos.
- No se ejecutaron Windows, WPF, Pester, construcción EXE/MSI, firma o despliegue de producción en este entorno Linux.

La página 404 conserva rutas absolutas `/Advanced_Tool_Suite/` para funcionar al solicitar una dirección anidada en GitHub Project Pages. Si se cambia el nombre del repositorio o se usa un dominio propio, hay que adaptar esas rutas. El servidor estático de previsualización en la raíz sirve inicio/guía/seguridad; no simula por sí mismo las rutas y respuestas 404 de Pages.

## Mantenimiento

Desde la raíz del repositorio:

```console
python packaging/Build-Site-Catalog.py
python packaging/Build-Site-Catalog.py --check
python packaging/Check-Repository.py
python packaging/Build-Bootstrap.py
python -m unittest discover -s tests -v
```

El generador modifica únicamente el bloque entre `ATS_CATALOG_START` y `ATS_CATALOG_END` en `site/index.html`. No edites manualmente los nombres y descripciones generados. Si cambia el número de herramientas, revisa también las cifras de la portada y las pruebas deliberadamente fijadas a 42.

Previsualización local (sin publicar):

```console
python -m http.server 8000 --bind 0.0.0.0 --directory site
```

Abre `/`, `/guia.html` y `/seguridad.html`. En un equipo compartido, limita el acceso al puerto o utiliza una interfaz local: `0.0.0.0` expone el servidor a las interfaces disponibles.

## Pendientes antes de publicar

1. Revisar esta rama y validar los checks Windows de su revisión concreta.
2. Confirmar permisos y configuración de Pages con el propietario. El workflow sigue siendo manual y limitado a `main`.
3. Comprobar la URL realmente desplegada antes de usarla en About/Website.
4. Revisar en Safari/Firefox, con zoom, pantalla táctil y lectores de pantalla. Las pruebas automáticas anteriores no cubren todas esas combinaciones.
5. Si se necesita un catálogo con búsqueda, valorar primero accesibilidad, privacidad y CSP antes de incorporar JavaScript. No se ha añadido un buscador simulado.

Las cabeceras HTTP, TLS, registros del hosting y protecciones GitHub no se configuran mediante este HTML. No se promete WAF, seguridad absoluta, autenticidad por hash o recuperación universal de cambios.

## Ampliación: portada GitHub y primera sesión (2026-11-01)

Revisión de los 20 puntos de esta entrega:

1. Logo NEXUS local visible en GitHub.
2. Lema propio «Diagnostica. Organiza. Decide.».
3. Propuesta de valor fiel a Windows/WPF.
4. Banner SVG original, no captura simulada.
5. Alternativa textual en Markdown y SVG.
6. Navegación con anclas a encabezados reales.
7. Resumen separado de las advertencias de desarrollo.
8. Ecosistema web/aplicación/fuentes diferenciado.
9. Funciones y seis categorías sin inventar módulos.
10. Requisitos Windows visibles.
11. Autoextraíble documentado con verificación previa.
12. Ejecución portable diferenciada de instalación.
13. Instalación desde fuentes actualizada tras correcciones previas.
14. Apertura diaria desde Inicio, sin reinstalar.
15. Guía local `uso.html` con primera sesión de solo lectura.
16. Permisos/UAC en lugar de roles empresariales inexistentes.
17. FAQ nativa sin JavaScript.
18. Resúmenes EN/PT-BR reales, sin atribuir idiomas a la UI.
19. Publicación Pages pendiente explícita; consulta API devolvió 404.
20. Historial, pruebas y autoextraíble actualizados.

La nueva guía hereda CSP, navegación, foco, temas y reglas adaptables existentes. El banner es un recurso local sin scripts ni referencias remotas. La revisión de navegador de la entrega anterior no se atribuye a esta ampliación: estas modificaciones se validan con contratos estáticos y preview HTTP; quedan pendientes comprobaciones visuales/interactivas específicas y Pages real.
