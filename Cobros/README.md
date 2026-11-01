# Analizador de cobros

Panel local para revisar los pagos de los contribuyentes a partir de un Excel:

- **Quién no pagó** cada mes, según la columna **Contribuyente**.
- **Quién pagó fuera de plazo**: después de los primeros **10 días hábiles** del mes.
- **Gráficos dinámicos** y tablas dinámicas del **Importe ($)**: por mes, contribuyente, estado, día hábil de pago, rango de retraso u otras columnas del archivo.

> [!IMPORTANT]
> **Tu archivo no sale de tu equipo.** El Excel se lee dentro del navegador. La página bloquea cualquier conexión (`connect-src 'none'`) y funciona sin Internet. Solo recuerda tus ajustes (plazo, feriados y tema), nunca los datos.

## Cómo usarlo

1. Abre [`AnalizadorCobros.html`](AnalizadorCobros.html) con doble clic en Edge, Chrome o Firefox. No necesita instalación ni conexión.
2. Arrastra tu `.xls` a la página, o pulsa **Elegir archivo**.
3. El panel detecta las columnas y muestra el **Resumen**. Si algo no cuadra, revisa **Columnas y reglas**: ahí puedes elegir la fila de encabezados, asignar cada columna y cambiar el plazo o los feriados.
4. Recorre las pestañas:

| Pestaña | Qué muestra |
| --- | --- |
| Resumen | Total cobrado, % de pagos en plazo, pagos fuera de plazo, quién no pagó el último mes cerrado y los gráficos principales |
| No pagaron | Lista por mes, matriz contribuyente × mes (✓ en plazo · ! fuera de plazo · ✗ no pagó) y deudores acumulados con deuda estimada |
| Fuera de plazo | Cada pago tardío con su fecha límite, días hábiles de retraso y ranking de contribuyentes impuntuales |
| Gráficos dinámicos | Tabla dinámica configurable con filas, series, medida (suma, conteo, promedio, máximo, mínimo, contribuyentes distintos), filtros, porcentajes y gráfico; clic en una barra para ver el detalle |
| Datos | Todas las filas leídas, con su resultado y avisos (sin fecha, sin importe, totales omitidos, posibles duplicados) |
| Columnas y reglas | Asignación de columnas, hojas incluidas, plazo, sábados, feriados y formato numérico |

Cada tabla se exporta a **CSV**, que abre Excel con acentos y separador correctos. Cada gráfico se exporta a **PNG**. **Imprimir** genera un informe en papel o PDF.

¿Quieres verlo antes de usar tus datos? Pulsa **Ver un ejemplo**, o abre [`ejemplo/cobros-ejemplo.xls`](ejemplo/cobros-ejemplo.xls). Son 36 contribuyentes **ficticios** de enero a octubre de 2026.

## Qué columnas necesita

Una fila por pago. Los nombres de los encabezados pueden variar: el panel reconoce sinónimos y, si no los encuentra, infiere las columnas por su contenido.

| Columna | ¿Obligatoria? | Encabezados reconocidos (ejemplos) |
| --- | --- | --- |
| Contribuyente | Sí | Contribuyente, Cliente, Nombre, Razón social, Titular |
| Fecha de pago | Sí | Fecha de pago, Fecha, Fecha de cobro, Pagado el |
| Importe ($) | Sí | Importe ($), Monto, Cobrado, Valor, Cuota |
| Mes o período | No | Mes, Período, Mes pagado: úsala si un pago corresponde a otro mes |
| Estado | No | Estado, Situación: «Pendiente» o «No pagó» no cuentan como pago |

- Las filas de título, las vacías y las de **totales** se omiten, y se listan en **Datos**.
- Los nombres se agrupan sin distinguir mayúsculas, acentos ni espacios dobles: «ADRIAN DELGADO SUAREZ» y «Adrián Delgado Suárez» son el mismo contribuyente. Grafías distintas, como «Ma.» y «María», no se unen.
- Se aceptan importes como número o como texto (`$1,250.00`, `1.250,00`, `1 250 CUP`) y fechas como fecha de Excel o como texto (`15/01/2026`, `15-ene-2026`, `15 de enero de 2026`).

## La regla del plazo

Un pago está **en plazo** si su fecha es igual o anterior a la **fecha límite** del mes. La fecha límite es el **10.º día hábil**.

- **Días hábiles:** de lunes a viernes, sin feriados. Puedes incluir los sábados o cambiar el número de días (1 a 22).
- **Feriados predeterminados (Cuba):**
  - 1 y 2 de enero, 1.º de mayo, 25, 26 y 27 de julio, 10 de octubre, 25 y 31 de diciembre.
  - **Viernes Santo**.
  - Si el 1.º de mayo o el 10 de octubre caen en domingo, se descansa el lunes siguiente.
  - Puedes añadir cierres o feriados declarados (una fecha por línea) o elegir «Sin feriados».
- **Mes de cada pago:** el de su fecha, o el de la columna Mes/Período si existe. Con esa columna, un pago de enero hecho en febrero cuenta como enero **fuera de plazo**.
- **Fin de semana o feriado:** un pago en sábado, domingo o feriado cuenta como hecho el siguiente día hábil.
- **No pagó:** el contribuyente no tiene ningún pago válido de ese mes y su fecha límite ya pasó. Mientras el plazo sigue abierto, el mes figura como **pendiente**.
- **Contribuyentes esperados:** todos los que aparecen en el archivo. Con **Exigir desde su primer pago**, los meses anteriores a su primer pago no se cuentan (útil para altas nuevas).

Fechas límite de 2026 con los feriados de Cuba:

| Ene | Feb | Mar | Abr | May | Jun | Jul | Ago | Sep | Oct | Nov | Dic |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 16 | 13 | 13 | 15 | 15 | 12 | 14 | 14 | 14 | 14 | 13 | 14 |

En abril, el Viernes Santo (3 de abril) desplaza el plazo hasta el día 15.

## Formatos admitidos

- `.xls` de Excel 97-2003, el formato habitual. Los `.xls` de Excel 5/95 se leen de forma básica.
- `.xlsx` y `.xlsm`.
- `.csv` y `.txt` con coma, punto y coma o tabulador, en UTF-8 o Windows-1252.
- XML de Excel 2003 y tablas HTML guardadas como `.xls`.

No se admiten libros con contraseña, `.xlsb` ni `.ods`. Ábrelos en Excel y guárdalos como `.xlsx` o `.xls`. Si un archivo falla, el panel explica el motivo; guardarlo de nuevo como `.xlsx` o CSV suele resolverlo.

## Privacidad: no subas datos de clientes

- El procesamiento es local. No hay servidor, analítica, cookies ni recursos externos.
- **El repositorio es público.** Nunca añadas al repositorio los Excel de tus clientes. `.gitignore` ignora `*.xls`, `*.xlsx`, `*.xlsm`, `*.xlsb`, `*.ods` y `*.csv`, salvo los ejemplos ficticios de `Cobros/ejemplo/` y `tests/fixtures/`.
- Los CSV y PNG exportados contienen datos de clientes. Guárdalos fuera de la carpeta del repositorio.

## Estado honesto

- Probado con los datos de ejemplo:
  - en `.xls` (generado con xlwt) y `.xlsx` (openpyxl);
  - con un `.xls` de 800 textos que fuerza registros CONTINUE y UTF-16;
  - con `.xls` sintéticos (mini-stream, fórmulas, fechas 1904), CSV, HTML y XML;
  - en Chromium, con la interfaz completa.
- Todavía **no se ha probado con el archivo real** del usuario ni con `.xls` guardados por versiones concretas de Excel. Si algo no se lee bien, revisa la pestaña **Datos** y avisa del caso, sin compartir datos reales.
- La **deuda estimada** es orientativa: meses sin pagar × importe habitual (mediana de sus pagos). No es un saldo contable.
- Los feriados extraordinarios o cambios de calendario deben añadirse a mano en **Columnas y reglas**.

## Mantenimiento

- Todo está en un único archivo, [`AnalizadorCobros.html`](AnalizadorCobros.html), sin dependencias. Contiene un `<script>` de núcleo (lectura de archivos, calendario, análisis y tablas dinámicas) y otro de interfaz.
- Tras editarlo, recalcula la CSP por hash con [`Build-Cobros-CSP.py`](../packaging/Build-Cobros-CSP.py). `--check` comprueba que esté sincronizada.
- Pruebas:
  - [`cobros-harness.mjs`](../tests/cobros-harness.mjs): núcleo, con Node.js 18 o superior;
  - [`test_cobros.py`](../tests/test_cobros.py): aislamiento y CSP. Ambas se ejecutan con `python -m unittest discover -s tests`.
- Los ejemplos se regeneran con [`Build-Cobros-Ejemplos.py`](../packaging/Build-Cobros-Ejemplos.py), que necesita Node.js, `xlwt` y `openpyxl`.
