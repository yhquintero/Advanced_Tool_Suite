// Pruebas del núcleo del Analizador de cobros con Node.js >= 18, sin dependencias.
// Ejecuta el <script id="cobros-core"> real de Cobros/AnalizadorCobros.html (no una copia).
// Uso: node tests/cobros-harness.mjs
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const html = fs.readFileSync(path.join(ROOT, 'Cobros', 'AnalizadorCobros.html'), 'utf8');
const match = html.match(/<script id="cobros-core">([\s\S]*?)<\/script>/);
if (!match) { console.error('No se encontró el script cobros-core'); process.exit(1); }
vm.runInThisContext(match[1], { filename: 'cobros-core.js' });
const C = globalThis.CobrosCore;

let passed = 0; let failed = 0; let skipped = 0;
const queue = [];
const test = (name, fn) => queue.push({ name, fn });
const eq = (actual, expected, label) => {
  const a = JSON.stringify(actual), e = JSON.stringify(expected);
  if (a !== e) throw new Error((label ? label + ': ' : '') + 'esperado ' + e + ', obtenido ' + a);
};
const ok = (cond, label) => { if (!cond) throw new Error(label || 'condición falsa'); };
const iso = d => (d instanceof Date ? d.toISOString().slice(0, 10) : d);
const sorted = o => Object.fromEntries(Object.entries(o).sort(([a], [b]) => (a < b ? -1 : 1)));
const readFixture = rel => new Uint8Array(fs.readFileSync(path.join(ROOT, rel)));
const csvBytes = text => new TextEncoder().encode(text);
async function analyzeText(text, opts = {}) {
  const wb = await C.readWorkbook(csvBytes(text), 'prueba.csv');
  const rows = wb.sheets[0].rows;
  const layout = C.detectLayout(rows);
  const built = C.buildRecords([{ file: 'prueba.csv', sheet: 'CSV', rows, layout }]);
  return { wb, layout, built, a: C.analyze(built.records, Object.assign({ today: C.utc(2026, 3, 1) }, opts)) };
}

/* ---------- calendario laboral ---------- */
test('fechas límite 2026 con feriados de Cuba (día hábil 10)', () => {
  const cal = C.makeCalendar({ diasHabiles: 10, feriados: 'cu' });
  const got = C.monthRange('2026-01', '2026-12').map(m => iso(cal.deadline(m)));
  eq(got, ['2026-01-16', '2026-02-13', '2026-03-13', '2026-04-15', '2026-05-15', '2026-06-12', '2026-07-14', '2026-08-14', '2026-09-14', '2026-10-14', '2026-11-13', '2026-12-14']);
});
test('Pascua y Viernes Santo', () => {
  eq([2024, 2025, 2026, 2027].map(y => iso(C.easterSunday(y))), ['2024-03-31', '2025-04-20', '2026-04-05', '2027-03-28']);
  const cal = C.makeCalendar({ feriados: 'cu' });
  ok(/Viernes Santo/.test(cal.holidayName(C.utc(2026, 4, 3)) || ''), 'Viernes Santo 2026');
  ok(!cal.isBusinessDay(C.utc(2026, 4, 3)), '03/04/2026 no es hábil');
});
test('traslado al lunes del 1.º de Mayo y del 10 de Octubre en domingo', () => {
  const cal = C.makeCalendar({ feriados: 'cu' });
  ok(C.utc(2022, 5, 1).getUTCDay() === 0, '01/05/2022 fue domingo');
  ok(/trasladado/.test(cal.holidayName(C.utc(2022, 5, 2)) || ''), 'lunes 02/05/2022');
  ok(C.utc(2027, 10, 10).getUTCDay() === 0, '10/10/2027 es domingo');
  ok(/trasladado/.test(cal.holidayName(C.utc(2027, 10, 11)) || ''), 'lunes 11/10/2027');
  ok(cal.isBusinessDay(C.utc(2026, 5, 4)), 'sin traslado cuando no cae en domingo');
});
test('variantes de la regla: sin feriados, sábados, fechas extra y N', () => {
  eq(iso(C.makeCalendar({ feriados: 'ninguno' }).deadline('2026-01')), '2026-01-14');
  eq(iso(C.makeCalendar({ feriados: 'cu', sabados: true }).deadline('2026-01')), '2026-01-14');
  eq(iso(C.makeCalendar({ feriados: 'cu', extras: '12/01/2026 Cierre de oficina' }).deadline('2026-01')), '2026-01-19');
  eq(iso(C.makeCalendar({ feriados: 'cu', diasHabiles: 1 }).deadline('2026-01')), '2026-01-05');
  eq(iso(C.makeCalendar({ feriados: 'cu', diasHabiles: 15 }).deadline('2026-02')), '2026-02-20');
  const parsed = C.parseHolidayList('03/01/2023 Receso\n2026-04-15 · Inventario\nfecha mala');
  eq(parsed.dates.map(d => iso(d.date)), ['2023-01-03', '2026-04-15']);
  eq(parsed.invalid, ['fecha mala']);
});
test('día hábil del pago: fin de semana cuenta como el siguiente hábil', () => {
  const cal = C.makeCalendar({ feriados: 'cu' });
  eq(cal.businessOrdinal(C.utc(2026, 1, 16)), 10);
  eq(cal.businessOrdinal(C.utc(2026, 1, 17)), 11, 'sábado tras el límite');
  eq(cal.businessOrdinal(C.utc(2026, 1, 1)), 1, 'feriado al inicio del mes');
  eq(cal.businessOrdinal(C.utc(2026, 1, 10)), 6, 'sábado antes del límite');
});

/* ---------- interpretación de valores ---------- */
test('importes en distintos formatos', () => {
  const cases = [['1.234,56', null, 1234.56], ['1,234.56', null, 1234.56], ['$ 1 250', null, 1250], ['(500)', null, -500], ['-75,5', null, -75.5],
    ['1.250', null, 1250], ['1.25', null, 1.25], ['12,5', null, 12.5], ['1.250', '.', 1.25], ['2.500,00 CUP', null, 2500], ['-', null, null], ['', null, null], ['abc', null, null]];
  for (const [text, hint, expected] of cases) eq(C.parseAmount(text, hint), expected, text);
  eq(C.parseAmount(1500), 1500);
});
test('fechas en texto, ISO, nombres de mes y número de serie de Excel', () => {
  const cases = [['15/01/2026', '2026-01-15'], ['2026-01-15', '2026-01-15'], ['15-ene-2026', '2026-01-15'], ['15 de enero de 2026', '2026-01-15'],
    ['1/2/26', '2026-02-01'], ['lunes, 2 de marzo de 2026', '2026-03-02'], ['31/02/2026', null], ['hola', null], ['15.01.2026 10:30', '2026-01-15']];
  for (const [text, expected] of cases) eq(iso(C.parseDate(text, 'dmy')), expected, text);
  eq(iso(C.parseDate('01/15/2026', 'mdy')), '2026-01-15');
  eq(iso(C.parseDate(45672)), '2025-01-15');
  eq(iso(C.excelSerialToDate(46027)), '2026-01-05');
  eq(iso(C.excelSerialToDate(44566, true)), '2026-01-06');
});
test('período, estado y formatos de celda de fecha', () => {
  const feb = C.utc(2026, 2, 3);
  eq(['Enero 2026', '01/2026', '2026-01', 'ene-26', 'Mes de enero'].map(v => C.parsePeriod(v, feb)), ['2026-01', '2026-01', '2026-01', '2026-01', '2026-01']);
  eq(C.parsePeriod(3, feb), '2026-03'); eq(C.parsePeriod(202604, feb), '2026-04'); eq(C.parsePeriod(C.utc(2026, 5, 1), feb), '2026-05');
  eq(['Pagado', 'Pendiente', 'No pagó', 'SI', 'debe', ''].map(C.parseEstado), [true, false, false, true, false, null]);
  eq(['dd/mm/yyyy', 'd-mmm-yy', '[$-es-ES]mmmm yyyy', 'h:mm', '#,##0.00', '"Total" 0', 'General', '0.00E+00', '[Red]#,##0'].map(C.isDateFormatCode), [true, true, true, true, false, false, false, false, false]);
});

/* ---------- reglas de negocio con un caso pequeño conocido ---------- */
const CASE = ['Contribuyente;Fecha de pago;Importe ($)', 'Ana Pérez;05/01/2026;1.000,00', 'Ana Pérez;16/01/2026;50,00', 'Luis Gómez;19/01/2026;800,00',
  'Pedro Ruiz;09/01/2026;300,00', 'Marta Díaz;10/02/2026;1.200,00', 'ANA PEREZ;13/02/2026;1.000,00', 'Luis Gómez;14/02/2026;800,00', 'Total;;4.150,00'].join('\n');
test('en plazo, fuera de plazo, no pagó y agrupación de nombres', async () => {
  const { layout, built, a } = await analyzeText(CASE);
  eq(sorted(layout.mapping), sorted({ contribuyente: 0, fecha: 1, importe: 2 }));
  eq(built.issues.map(i => i.type), ['total']);
  eq(a.months, ['2026-01', '2026-02']);
  eq(a.contribs.map(c => c.name), ['Ana Pérez', 'Luis Gómez', 'Marta Díaz', 'Pedro Ruiz']);
  const st = key => a.months.map(m => a.matrix[key][m].estado);
  eq(st('ana perez'), ['en_plazo', 'en_plazo']);
  eq(st('luis gomez'), ['fuera_plazo', 'fuera_plazo']);
  eq(st('marta diaz'), ['no_pago', 'en_plazo']);
  eq(st('pedro ruiz'), ['en_plazo', 'no_pago']);
  eq([a.summary.pagos, a.summary.fueraPlazo, a.summary.total], [7, 2, 5150]);
  const late = a.payments.filter(p => p.estado === 'fuera_plazo').map(p => [iso(p.fecha), p.retrasoHabiles, p.retrasoNaturales, p.diaHabil]);
  eq(late, [['2026-01-19', 1, 3, 11], ['2026-02-14', 1, 1, 11]]);
  eq(a.lastClosed, '2026-02');
  eq(a.perMonth.map(m => [m.periodo, m.enPlazo, m.fueraPlazo, m.noPago]), [['2026-01', 2, 1, 1], ['2026-02', 2, 1, 1]]);
  const pedro = a.contribs.find(c => c.key === 'pedro ruiz');
  eq([pedro.mesesNoPagados, pedro.rachaNoPago, pedro.importeHabitual, pedro.deudaEstimada], [1, 1, 300, 300]);
});
test('pendiente mientras el plazo del mes sigue abierto', async () => {
  const { a } = await analyzeText(CASE, { today: C.utc(2026, 2, 12) });
  eq(a.matrix['pedro ruiz']['2026-02'].estado, 'pendiente');
  eq(a.lastClosed, '2026-01');
  const { a: b } = await analyzeText(CASE, { today: C.utc(2026, 2, 14) });
  eq(b.matrix['pedro ruiz']['2026-02'].estado, 'no_pago');
});
test('exigir desde el primer pago y rango de meses', async () => {
  const { a } = await analyzeText(CASE, { desdePrimerPago: true });
  eq(a.matrix['marta diaz']['2026-01'].estado, 'no_aplica');
  const { a: r } = await analyzeText(CASE, { desde: '2026-02', hasta: '2026-03' });
  eq(r.months, ['2026-02', '2026-03']);
  eq(r.summary.pagos, 3);
  eq(r.matrix['ana perez']['2026-03'].estado, 'pendiente');
});
test('estado «Pendiente» y columna de período', async () => {
  const text = 'Cliente,Mes,Fecha,Monto,Estado\nRosa,Enero 2026,20/02/2026,500,Pagado\nRosa,Febrero 2026,,500,Pendiente\nJuan,Enero 2026,10/01/2026,400,Pagado\nJuan,Febrero 2026,04/02/2026,400,Pagado';
  const { layout, a } = await analyzeText(text);
  eq(sorted(layout.mapping), sorted({ contribuyente: 0, fecha: 2, importe: 3, periodo: 1, estado: 4 }));
  eq(a.matrix.rosa['2026-01'].estado, 'fuera_plazo', 'enero pagado en febrero');
  eq(a.matrix.rosa['2026-02'].estado, 'no_pago');
  eq(a.payments.find(p => p.key === 'rosa').diaHabil, null);
});
test('detección de columnas por contenido cuando no hay encabezados reconocibles', () => {
  const rows = [['Dato 1', 'Dato 2', 'Dato 3'], [C.utc(2026, 1, 5), 'Ana Pérez', 100], [C.utc(2026, 1, 7), 'Luis Gómez', 250.5], [C.utc(2026, 2, 3), 'Ana Pérez', 100]];
  const layout = C.detectLayout(rows);
  eq([layout.mapping.fecha, layout.mapping.contribuyente, layout.mapping.importe, layout.complete], [0, 1, 2, true]);
  const forced = C.detectLayout(rows, { headerRow: 1 });
  eq(forced.headerRow, 1);
});

/* ---------- tablas dinámicas y exportación ---------- */
test('tabla dinámica: totales, porcentajes, top y obligaciones', async () => {
  const { a } = await analyzeText(CASE);
  const pv = C.pivot(a, { rows: 'mes', series: 'estado', measure: 'suma' });
  eq(pv.rows.map(r => r.key), ['2026-01', '2026-02']);
  eq(pv.series.map(s => s.key), ['en_plazo', 'fuera_plazo']);
  eq(pv.values, [[1350, 800], [2200, 800]]);
  eq(pv.grandTotal, 5150);
  const pct = C.pivot(a, { rows: 'contribuyente', measure: 'suma', showAs: 'pct_total' });
  ok(Math.abs(pct.rowTotals.reduce((s, v) => s + v, 0) - 1) < 1e-9, 'porcentajes suman 100 %');
  const top = C.pivot(a, { rows: 'contribuyente', measure: 'suma', top: 2 });
  eq([top.rows.length, top.hiddenRows, top.rows[0].label], [2, 2, 'Ana Pérez']);
  const obl = C.pivot(a, { source: 'obligaciones', rows: 'mes', series: 'estado', measure: 'conteo' });
  eq(obl.series.map(s => s.key), ['en_plazo', 'fuera_plazo', 'no_pago']);
  eq(obl.values, [[2, 1, 1], [2, 1, 1]]);
  eq(C.pivotKey('diaHabil', a.payments[0], 'pagos'), String(a.payments[0].diaHabil));
});
test('CSV para Excel: BOM, separador regional y protección contra fórmulas', () => {
  const us = C.toCSV(['Nombre', 'Importe'], [['=HYPERLINK("x")', 1234.5], ['Ana; "La Rubia"', 10]], 'us');
  ok(us.startsWith('\ufeffNombre,Importe\r\n'), 'cabecera us');
  ok(us.includes(`"'=HYPERLINK(""x"")",1234.5`), 'fórmula neutralizada');
  ok(us.includes('"Ana; ""La Rubia""",10'), 'comillas');
  const eu = C.toCSV(['Importe'], [[1234.5]], 'eu');
  ok(eu.includes('1234,5'), 'coma decimal');
  eq(C.formatMoney(-1234.5, 'eu'), '-$1.234,50');
  eq(C.formatMoney(1234567.891, 'us'), '$1,234,567.89');
});

/* ---------- lectores de archivos ---------- */
test('ejemplo .xls (BIFF8) igual a los datos de ejemplo del núcleo', async () => {
  const wb = await C.readWorkbook(readFixture('Cobros/ejemplo/cobros-ejemplo.xls'), 'cobros-ejemplo.xls');
  eq(wb.format, 'Excel 97-2003 (.xls)');
  eq(wb.sheets.map(s => s.name), ['Cobros 2026', 'Notas']);
  const got = wb.sheets[0].rows; const exp = C.sampleRows();
  eq(got.length, exp.length, 'filas');
  for (let r = 0; r < exp.length; r++) {
    for (let c = 0; c < Math.max(exp[r].length, got[r].length); c++) {
      if (r === exp.length - 1 && c === 4) continue; // la fila TOTAL es una fórmula SUMA en el .xls
      eq(iso(got[r][c] ?? null), iso(exp[r][c] ?? null), `fila ${r + 1} col ${c + 1}`);
    }
  }
  const layout = C.detectLayout(got);
  const built = C.buildRecords([{ file: 'x', sheet: 'Cobros 2026', rows: got, layout }]);
  const a = C.analyze(built.records, { today: C.utc(2026, 11, 1) });
  eq([a.summary.pagos, a.summary.contribuyentes, built.issues.length], [314, 37, 1]);
});
test('ejemplo .xlsx igual a los datos de ejemplo', async () => {
  if (typeof DecompressionStream === 'undefined') { skipped++; return 'omitido: Node sin DecompressionStream'; }
  const wb = await C.readWorkbook(readFixture('tests/fixtures/cobros-ejemplo.xlsx'), 'cobros-ejemplo.xlsx');
  eq(wb.format, 'Excel (.xlsx)');
  const got = wb.sheets[0].rows; const exp = C.sampleRows();
  eq(got.length, exp.length);
  exp.forEach((row, r) => row.forEach((v, c) => eq(iso(got[r][c] ?? null), iso(v ?? null), `fila ${r + 1} col ${c + 1}`)));
});
export function sstStrings(count = 800) {
  // Misma secuencia que packaging/Build-Cobros-Ejemplos.py (generador congruencial).
  let seed = 20260115;
  const next = () => (seed = (Math.imul(seed, 1103515245) + 12345) & 0x7fffffff);
  const alphabet = 'abcdefghijklmnñopqrstuvwxyzáéíóúü ABCDEFGHIJKLMNÑOPQRSTUVWXYZ';
  const out = [];
  for (let i = 0; i < count; i++) {
    const n = 5 + (next() % 56);
    let s = '';
    for (let k = 0; k < n; k++) s += alphabet[next() % alphabet.length];
    s = s.trim() || 'x';
    if (i % 3 === 0) s += ' € Γ ' + i;
    if (i % 5 === 0) s = s.repeat(4);
    out.push(String(i).padStart(4, '0') + ' ' + s);
  }
  return out;
}
test('SST con registros CONTINUE y textos UTF-16 (.xls de xlwt)', async () => {
  const wb = await C.readWorkbook(readFixture('tests/fixtures/cobros-sst-continue.xls'), 'sst.xls');
  const rows = wb.sheets[0].rows; const strings = sstStrings();
  eq(rows.length, strings.length);
  strings.forEach((s, i) => { eq(rows[i][0], s, 'texto ' + i); eq(rows[i][1], i * 1.25, 'número ' + i); eq(rows[i][2], i, 'entero ' + i); });
});

/* Generador mínimo de .xls (CFB v3 + BIFF8) para casos difíciles de producir con bibliotecas. */
const le16 = n => [n & 255, (n >> 8) & 255];
const le32 = n => [n & 255, (n >>> 8) & 255, (n >>> 16) & 255, (n >>> 24) & 255];
const f64 = n => { const b = new Uint8Array(8); new DataView(b.buffer).setFloat64(0, n, true); return [...b]; };
const rec = (type, bytes) => [...le16(type), ...le16(bytes.length), ...bytes];
const compressed = s => [...s].map(ch => ch.charCodeAt(0));
const utf16 = s => [...s].flatMap(ch => le16(ch.charCodeAt(0)));
function biffWorkbook({ date1904 = false, filepass = false } = {}) {
  const globals = [];
  globals.push(rec(0x0809, [...le16(0x0600), ...le16(0x0005), ...le16(0), ...le16(0), ...le32(0), ...le32(0)]));
  if (filepass) globals.push(rec(0x002F, [...le16(1), ...le16(1)]));
  globals.push(rec(0x0042, le16(1200)));
  globals.push(rec(0x0022, le16(date1904 ? 1 : 0)));
  globals.push(rec(0x041E, [...le16(164), ...le16(10), 0, ...compressed('dd/mm/yyyy')]));
  const xf = ifmt => rec(0x00E0, [...le16(0), ...le16(ifmt), ...new Array(16).fill(0)]);
  globals.push(xf(0), xf(164), xf(14));
  const sheetName = 'Pagos ñ';
  const boundsheetAt = globals.flat().length;
  globals.push(rec(0x0085, [...le32(0), 0, 0, sheetName.length, 0, ...compressed(sheetName)]));
  // SST: «Contribuyente», «Fecha de pago», «Importe ($)», y un nombre cuyo texto pasa de 8 bits a UTF-16 en un CONTINUE.
  const longName = 'José Martí Pérez'; const first = longName.slice(0, 6); const rest = longName.slice(6) + ' Ω';
  const sst = [...le32(4), ...le32(4)];
  for (const s of ['Contribuyente', 'Fecha de pago', 'Importe ($)']) sst.push(...le16(s.length), 0, ...compressed(s));
  sst.push(...le16(first.length + rest.length), 0, ...compressed(first));
  globals.push(rec(0x00FC, sst));
  globals.push(rec(0x003C, [1, ...utf16(rest)]));
  globals.push(rec(0x000A, []));
  const sheet = [];
  sheet.push(rec(0x0809, [...le16(0x0600), ...le16(0x0010), ...le16(0), ...le16(0), ...le32(0), ...le32(0)]));
  const cell = (r, c, x) => [...le16(r), ...le16(c), ...le16(x)];
  sheet.push(rec(0x00FD, [...cell(0, 0, 0), ...le32(0)]), rec(0x00FD, [...cell(0, 1, 0), ...le32(1)]), rec(0x00FD, [...cell(0, 2, 0), ...le32(2)]));
  sheet.push(rec(0x00FD, [...cell(1, 0, 0), ...le32(3)]));
  sheet.push(rec(0x0203, [...cell(1, 1, 1), ...f64(date1904 ? 44566 : 46028)]));
  sheet.push(rec(0x0203, [...cell(1, 2, 0), ...f64(1234.5)]));
  sheet.push(rec(0x0204, [...cell(2, 0, 0), ...le16(9), 1, ...utf16('Ana Ωmega')]));
  sheet.push(rec(0x027E, [...cell(2, 1, 2), ...le32((((date1904 ? 44567 : 46029) << 2) | 2) >>> 0)]));
  sheet.push(rec(0x027E, [...cell(2, 2, 0), ...le32((((12345 << 2) | 2 | 1)) >>> 0)]));
  sheet.push(rec(0x0006, [...cell(3, 0, 0), 0, 0, 0, 0, 0, 0, 0xFF, 0xFF, ...le16(0), ...le32(0), ...le16(0)]));
  sheet.push(rec(0x0207, [...le16(10), 0, ...compressed('Luis Gómez')]));
  sheet.push(rec(0x00BD, [...le16(3), ...le16(1), ...le16(1), ...le32((((date1904 ? 44568 : 46030) << 2) | 2) >>> 0), ...le16(0), ...le32(((500 << 2) | 2) >>> 0), ...le16(2)]));
  sheet.push(rec(0x0205, [...cell(4, 0, 0), 1, 0]));
  sheet.push(rec(0x0006, [...cell(4, 2, 0), ...f64(99.75), ...le16(0), ...le32(0), ...le16(0)]));
  sheet.push(rec(0x000A, []));
  const g = globals.flat(); const sh = sheet.flat();
  const offset = g.length;
  g.splice(boundsheetAt + 4, 4, ...le32(offset));
  return new Uint8Array([...g, ...sh]);
}
function cfbWithMiniStream(stream) {
  const S = 512, END = 0xFFFFFFFE, FREE = 0xFFFFFFFF;
  const miniSectors = Math.ceil(stream.length / 64);
  const container = new Uint8Array(Math.ceil((miniSectors * 64) / S) * S); container.set(stream);
  const containerSectors = container.length / S;
  const total = 3 + containerSectors;
  const out = new Uint8Array(S * (total + 1)); const dv = new DataView(out.buffer);
  [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1].forEach((b, i) => { out[i] = b; });
  dv.setUint16(0x18, 0x3E, true); dv.setUint16(0x1A, 3, true); dv.setUint16(0x1C, 0xFFFE, true); dv.setUint16(0x1E, 9, true); dv.setUint16(0x20, 6, true);
  dv.setUint32(0x2C, 1, true); dv.setUint32(0x30, 1, true); dv.setUint32(0x38, 4096, true); dv.setUint32(0x3C, 2, true); dv.setUint32(0x40, 1, true);
  dv.setUint32(0x44, END, true); dv.setUint32(0x48, 0, true);
  for (let i = 0; i < 109; i++) dv.setUint32(0x4C + i * 4, i === 0 ? 0 : FREE, true);
  const sec = n => S * (n + 1);
  for (let i = 0; i < 128; i++) {
    let v = FREE;
    if (i === 0) v = 0xFFFFFFFD; else if (i === 1 || i === 2) v = END;
    else if (i >= 3 && i < 3 + containerSectors) v = i === 2 + containerSectors ? END : i + 1;
    dv.setUint32(sec(0) + i * 4, v, true);
  }
  const entry = (idx, name, type, start, size, child) => {
    const base = sec(1) + idx * 128;
    [...name].forEach((ch, i) => dv.setUint16(base + i * 2, ch.charCodeAt(0), true));
    dv.setUint16(base + 64, (name.length + 1) * 2, true); out[base + 66] = type; out[base + 67] = 1;
    dv.setUint32(base + 68, FREE, true); dv.setUint32(base + 72, FREE, true); dv.setUint32(base + 76, child, true);
    dv.setUint32(base + 116, start, true); dv.setUint32(base + 120, size, true);
  };
  entry(0, 'Root Entry', 5, 3, miniSectors * 64, 1);
  entry(1, 'Workbook', 2, 0, stream.length, FREE);
  for (let i = 0; i < 128; i++) dv.setUint32(sec(2) + i * 4, i < miniSectors ? (i === miniSectors - 1 ? END : i + 1) : FREE, true);
  out.set(container, sec(3));
  return out;
}
test('.xls sintético: mini-stream, NUMBER, LABEL UTF-16, RK, MULRK, FORMULA+STRING, BOOLERR y SST partido', async () => {
  for (const date1904 of [false, true]) {
    const wb = await C.readWorkbook(cfbWithMiniStream(biffWorkbook({ date1904 })), 'sintetico.xls');
    eq(wb.sheets.map(s => s.name), ['Pagos ñ']);
    const rows = wb.sheets[0].rows.map(r => r.map(iso));
    eq(rows, [
      ['Contribuyente', 'Fecha de pago', 'Importe ($)'],
      ['José Martí Pérez Ω', '2026-01-06', 1234.5],
      ['Ana Ωmega', '2026-01-07', 123.45],
      ['Luis Gómez', '2026-01-08', 500],
      [true, null, 99.75]
    ], date1904 ? 'sistema 1904' : 'sistema 1900');
  }
});
test('mensajes claros para archivos protegidos, vacíos o no compatibles', async () => {
  const fails = async (bytes, re) => {
    try { await C.readWorkbook(bytes, 'x'); } catch (e) { ok(e.name === 'CobrosError' && re.test(e.message), 'mensaje: ' + e.message); return; }
    throw new Error('debía fallar: ' + re);
  };
  await fails(cfbWithMiniStream(biffWorkbook({ filepass: true })), /contraseña/);
  await fails(new Uint8Array(0), /vacío/);
  await fails(new Uint8Array([0, 1, 2, 3, 4, 5, 0, 7]), /no reconocido/);
  await fails(new Uint8Array([0xD0, 0xCF, 0x11, 0xE0, 1, 2]), /incompleto|dañado/);
});
test('CSV con punto y coma, comillas, BOM y Windows-1252', async () => {
  const wb = await C.readWorkbook(csvBytes('\ufeffContribuyente;Importe ($);Fecha de pago\r\n"Pérez; Ana";"1.500,00";05/01/2026\r\n'), 'a.csv');
  eq(wb.sheets[0].rows, [['Contribuyente', 'Importe ($)', 'Fecha de pago'], ['Pérez; Ana', '1.500,00', '05/01/2026']]);
  const latin = new Uint8Array([...new TextEncoder().encode('Contribuyente,Importe\nPe'), 0xF1, ...new TextEncoder().encode('a,10\n')]);
  eq((await C.readWorkbook(latin, 'b.csv')).sheets[0].rows[1], ['Peña', '10']);
});
test('tabla HTML guardada como .xls y XML de Excel 2003', async () => {
  const htmlXls = '<html><head><style>td{}</style></head><body><table><tr><th>Contribuyente</th><th>Fecha de pago</th><th>Importe ($)</th></tr><tr><td>Ana &amp; Cía</td><td>05/01/2026</td><td>$1,000.00</td></tr><tr><td colspan="2">Nota<br>larga</td><td>3</td></tr></table></body></html>';
  const h = await C.readWorkbook(csvBytes(htmlXls), 'html.xls');
  eq(h.sheets[0].rows, [['Contribuyente', 'Fecha de pago', 'Importe ($)'], ['Ana & Cía', '05/01/2026', '$1,000.00'], ['Nota larga', null, '3']]);
  const xml = '<?xml version="1.0"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"><Worksheet ss:Name="Cobros"><Table><Row><Cell><Data ss:Type="String">Contribuyente</Data></Cell><Cell><Data ss:Type="String">Fecha</Data></Cell><Cell ss:Index="4"><Data ss:Type="String">Importe</Data></Cell></Row><Row><Cell><Data ss:Type="String">Ana</Data></Cell><Cell><Data ss:Type="DateTime">2026-01-05T00:00:00.000</Data></Cell><Cell ss:Index="4"><Data ss:Type="Number">150.5</Data></Cell></Row></Table></Worksheet></Workbook>';
  const x = await C.readWorkbook(csvBytes(xml), 'xml.xls');
  eq(x.sheets[0].name, 'Cobros');
  eq(x.sheets[0].rows.map(r => r.map(iso)), [['Contribuyente', 'Fecha', null, 'Importe'], ['Ana', '2026-01-05', null, 150.5]]);
});
test('datos de ejemplo deterministas y ficticios', () => {
  const a = C.sampleRows(); const b = C.sampleRows();
  eq(a.map(r => r.map(iso)), b.map(r => r.map(iso)));
  ok(/FICTICIOS/.test(a[0][0]), 'marcado como ficticio');
});

/* ---------- ejecución ---------- */
for (const t of queue) {
  try {
    const note = await t.fn();
    if (typeof note === 'string' && note.startsWith('omitido')) console.log('omitido ' + t.name + ' (' + note + ')');
    else { passed++; console.log('ok      ' + t.name); }
  } catch (e) { failed++; console.log('FALLO   ' + t.name + '\n        ' + (e && e.stack ? e.stack.split('\n').slice(0, 3).join('\n        ') : e)); }
}
console.log(`\n${passed} correctas, ${failed} fallos, ${skipped} omitidas`);
process.exit(failed ? 1 : 0);
