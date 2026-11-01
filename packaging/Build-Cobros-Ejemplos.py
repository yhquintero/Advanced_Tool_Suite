#!/usr/bin/env python3
"""Regenera los archivos de ejemplo y de prueba del Analizador de cobros.

Los datos salen de ``CobrosCore.sampleRows()`` dentro de ``Cobros/AnalizadorCobros.html``
(36 contribuyentes ficticios, enero-octubre de 2026), así el .xls de ejemplo, el .xlsx
de prueba y el botón «Ver un ejemplo» del panel muestran exactamente lo mismo.

Requisitos solo para regenerar (no para usar el analizador):
    Node.js >= 18 y  python -m pip install xlwt==1.3.0 openpyxl==3.1.5

Salida:
    Cobros/ejemplo/cobros-ejemplo.xls        Excel 97-2003 (BIFF8), como el archivo del usuario
    tests/fixtures/cobros-ejemplo.xlsx       mismo contenido en Excel moderno
    tests/fixtures/cobros-sst-continue.xls   800 textos para forzar registros CONTINUE y UTF-16
"""
import datetime
import json
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
HTML = ROOT / 'Cobros' / 'AnalizadorCobros.html'

DUMP_SAMPLE = r"""
const fs = require('fs'); const vm = require('vm');
const html = fs.readFileSync(process.argv[1], 'utf8');
const m = html.match(/<script id="cobros-core">([\s\S]*?)<\/script>/);
if (!m) { console.error('No se encontró cobros-core'); process.exit(1); }
vm.runInThisContext(m[1]);
const rows = globalThis.CobrosCore.sampleRows().map(r => r.map(v => v instanceof Date ? { date: v.toISOString().slice(0, 10) } : v));
process.stdout.write(JSON.stringify(rows));
"""


def sst_strings(count=800):
    """Misma secuencia que sstStrings() en tests/cobros-harness.mjs."""
    seed = 20260115

    def nxt():
        nonlocal seed
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        return seed

    alphabet = 'abcdefghijklmnñopqrstuvwxyzáéíóúü ABCDEFGHIJKLMNÑOPQRSTUVWXYZ'
    out = []
    for i in range(count):
        n = 5 + nxt() % 56
        s = ''.join(alphabet[nxt() % len(alphabet)] for _ in range(n)).strip() or 'x'
        if i % 3 == 0:
            s += ' € Γ ' + str(i)  # fuera de Latin-1: obliga a guardar el texto en UTF-16
        if i % 5 == 0:
            s = s * 4
        out.append(f'{i:04d} {s}')
    return out


def sample_rows():
    node = shutil.which('node')
    if not node:
        raise SystemExit('Se necesita Node.js >= 18 para leer los datos de ejemplo del analizador.')
    raw = subprocess.check_output([node, '-e', DUMP_SAMPLE, str(HTML)], cwd=ROOT)
    return json.loads(raw)


def to_date(value):
    return datetime.datetime.strptime(value['date'], '%Y-%m-%d')


def write_xls(rows, path, xlwt):
    wb = xlwt.Workbook(encoding='utf-8')
    ws = wb.add_sheet('Cobros 2026')
    title = xlwt.easyxf('font: bold on, height 280')
    head = xlwt.easyxf('font: bold on; pattern: pattern solid, fore_colour gray25; borders: bottom thin')
    datef = xlwt.easyxf(num_format_str='DD/MM/YYYY')
    money = xlwt.easyxf(num_format_str='#,##0.00')
    header_row = next(i for i, r in enumerate(rows) if 'Contribuyente' in r)
    for r, row in enumerate(rows):
        if r == 0:
            ws.write_merge(0, 0, 0, 5, row[0], title)
            continue
        for c, v in enumerate(row):
            if v is None:
                continue
            if isinstance(v, dict):
                ws.write(r, c, to_date(v), datef)
            elif r == header_row:
                ws.write(r, c, v, head)
            elif isinstance(v, (int, float)) and c == 4:
                if row[1] == 'TOTAL':  # fila de totales como fórmula, igual que en una hoja real
                    ws.write(r, c, xlwt.Formula('SUM(E%d:E%d)' % (header_row + 2, r)), money)
                else:
                    ws.write(r, c, v, money)
            else:
                ws.write(r, c, v)
    for col, width in ((1, 34), (2, 28), (3, 14), (4, 14), (5, 28)):
        ws.col(col).width = 256 * width
    notes = wb.add_sheet('Notas')
    notes.write(0, 0, 'Datos ficticios generados para probar el Analizador de cobros. No corresponden a personas reales.')
    wb.save(str(path))


def write_xlsx(rows, path, openpyxl):
    from openpyxl.styles import Font
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = 'Cobros 2026'
    header_row = next(i for i, r in enumerate(rows) if 'Contribuyente' in r) + 1
    for r, row in enumerate(rows, start=1):
        for c, v in enumerate(row, start=1):
            if v is None:
                continue
            cell = ws.cell(row=r, column=c)
            if isinstance(v, dict):
                cell.value = to_date(v)
                cell.number_format = 'dd/mm/yyyy'
            else:
                cell.value = v
                if c == 5 and isinstance(v, (int, float)):
                    cell.number_format = '#,##0.00'
            if r == header_row:
                cell.font = Font(bold=True)
    fixed = datetime.datetime(2026, 1, 1)
    wb.properties.creator = 'NEXUS Advanced Tool Suite'
    wb.properties.created = fixed
    wb.properties.modified = fixed
    wb.save(str(path))


def write_sst(path, xlwt):
    wb = xlwt.Workbook(encoding='utf-8')
    ws = wb.add_sheet('Textos')
    for i, s in enumerate(sst_strings()):
        ws.write(i, 0, s)
        ws.write(i, 1, i * 1.25)
        ws.write(i, 2, i)
    wb.save(str(path))


def main():
    try:
        import openpyxl
        import xlwt
    except ImportError:
        raise SystemExit('Instala las dependencias de generación: python -m pip install xlwt==1.3.0 openpyxl==3.1.5')
    rows = sample_rows()
    targets = {
        'xls': ROOT / 'Cobros' / 'ejemplo' / 'cobros-ejemplo.xls',
        'xlsx': ROOT / 'tests' / 'fixtures' / 'cobros-ejemplo.xlsx',
        'sst': ROOT / 'tests' / 'fixtures' / 'cobros-sst-continue.xls',
    }
    for path in targets.values():
        path.parent.mkdir(parents=True, exist_ok=True)
    write_xls(rows, targets['xls'], xlwt)
    write_xlsx(rows, targets['xlsx'], openpyxl)
    write_sst(targets['sst'], xlwt)
    for path in targets.values():
        print(f'{path.relative_to(ROOT)}  {path.stat().st_size:,} bytes')
    return 0


if __name__ == '__main__':
    sys.exit(main())
