#!/usr/bin/env python3
"""Sincroniza el catalogo HTML con los metadatos del PS1, sin ejecutar PowerShell."""
from __future__ import annotations
import argparse
import html
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
START = '<!-- ATS_CATALOG_START -->'
END = '<!-- ATS_CATALOG_END -->'
CATEGORIES = ('Sistema', 'Mantenimiento', 'Red', 'Seguridad', 'Personalizacion', 'Energia')
# Orden de presentación; los nombres y permisos siempre proceden del PS1.
LABELS = {'Personalizacion': 'Personalización', 'Energia': 'Energía'}
TOOL = re.compile(r"@\{Id=(\d+); Name='((?:[^']|'')*)'; Category='((?:[^']|'')*)'; Description='((?:[^']|'')*)'; Admin=\$(true|false); Risk=\$(true|false)\}")


def tools():
    source = (ROOT / 'Tool/AdvancedToolSuite.ps1').read_text(encoding='utf-8-sig')
    # Leer solo el catalogo declarativo, no otros bloques del programa.
    source = source.split('$script:Tools = @(', 1)[1].split('\n)', 1)[0]
    records = []
    for match in TOOL.finditer(source):
        number, name, category, description, admin, risk = match.groups()
        records.append({'id': int(number), 'name': name.replace("''", "'"), 'category': category.replace("''", "'"), 'description': description.replace("''", "'"), 'admin': admin == 'true', 'risk': risk == 'true'})
    if sorted(r['id'] for r in records) != list(range(1, 43)):
        raise ValueError('El catalogo no tiene los 42 IDs esperados; revisa el formato antes de generar HTML.')
    return records


def render(records):
    categories = list(dict.fromkeys(r['category'] for r in records))
    ordered = [c for c in CATEGORIES if c in categories] + [c for c in categories if c not in CATEGORIES]
    chunks = []
    for category in ordered:
        selected = [r for r in records if r['category'] == category]
        label = html.escape(LABELS.get(category, category))
        chunks.append(f'      <details class="category"><summary>{label}<span class="category-count">{len(selected)} herramientas</span></summary><ul class="tool-list">')
        for record in selected:
            badge = ('UAC · confirmar' if record['admin'] else 'Confirmación') if record['risk'] else ('UAC' if record['admin'] else 'Abrir / consultar')
            warning = ' warning' if record['risk'] else ''
            chunks.append(f'        <li data-tool-id="{record["id"]}"><strong>{html.escape(record["name"])}</strong><span class="tool-permission{warning}">{badge}</span><small>{html.escape(record["description"])}</small></li>')
        chunks.append('      </ul></details>')
    return '\n'.join(chunks)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Verifica sin modificar archivos.')
    args = parser.parse_args()
    path = ROOT / 'site/index.html'
    source = path.read_text(encoding='utf-8')
    content = render(tools())
    if source.count(START) != 1 or source.count(END) != 1:
        raise ValueError('Faltan los marcadores unicos del catalogo HTML.')
    before, rest = source.split(START)
    _, after = rest.split(END)
    result = before + START + '\n' + content + '\n    ' + END + after
    if args.check:
        if source != result:
            raise SystemExit('Catalogo desactualizado: ejecuta python packaging/Build-Site-Catalog.py')
        print('Catalogo HTML sincronizado: 42 herramientas.')
    else:
        path.write_text(result, encoding='utf-8', newline='\n')
        print(f'Catalogo HTML generado: 42 herramientas, {len(set(t["category"] for t in tools()))} categorias.')


if __name__ == '__main__':
    main()
