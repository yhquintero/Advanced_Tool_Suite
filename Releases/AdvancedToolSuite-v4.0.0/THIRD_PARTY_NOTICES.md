# Componentes y avisos de terceros

La licencia [MIT](LICENSE) del proyecto no concede derechos sobre herramientas ajenas ni sustituye sus licencias.

| Componente | Uso | Distribución en este árbol |
| --- | --- | --- |
| Windows, Windows PowerShell, .NET Framework, WPF | Plataforma de ejecución | No se incluyen sus binarios |
| ps2exe | Construcción opcional del EXE | No se incluye el módulo; debe revisarse e instalarse aparte |
| WiX Toolset | Construcción opcional MSI | No se incluyen herramientas ni runtimes |
| Pester | Pruebas Windows | No se incluye módulo; CI instala la versión indicada |
| GitHub Actions de `actions/*` | CI y publicación opcional | Solo referencias por commit; conserva licencias de sus repositorios |
| Python | Generación y pruebas | No se distribuye el intérprete |
| LiveCharts / RSAT ActiveDirectory | Opciones de roadmap | No incorporados como nuevas dependencias de ejecución |

Comprueba los archivos de licencia de la versión exacta de cada dependencia antes de redistribuirla. No se presume que todas compartan MIT. Fijar una versión o SHA no elimina la necesidad de revisar avisos y vulnerabilidades.

Los iconos SVG y la identidad visual incluidos se generaron para el proyecto. No se incluyen fotografías, fuentes web ni bibliotecas gráficas remotas. Los mantenedores deben confirmar titularidad y atribuciones del código y recursos históricos; el nombre del repositorio no prueba derechos sobre cada contribución.

La versión canónica MIT está en inglés para facilitar su reconocimiento por GitHub y herramientas; [LICENSE.es.md](LICENSE.es.md) es traducción informativa. La documentación de riesgos y responsabilidades se mantiene separada del texto legal, sin añadir condiciones a la licencia MIT.
