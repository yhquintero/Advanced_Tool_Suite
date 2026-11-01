#!/usr/bin/env python3
"""Genera el unico PS1 autoextraible, sin dependencias Python externas."""
from __future__ import annotations

import base64
import hashlib
import io
import json
import pathlib
import re
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'Releases' / 'AdvancedToolSuite-v4.0.0-setup.ps1'
ROOT_FILES = (
    '.gitignore', 'README.md', 'LEEME-PRIMERO.md', 'MANUAL.md', 'BUILD.md',
    'CHANGELOG.md', 'LICENSE', 'LICENSE.es.md', 'SECURITY.md', 'CONTRIBUTING.md',
    'THIRD_PARTY_NOTICES.md', 'VERSION.json', 'install.ps1', 'uninstall.ps1',
)
TREES = ('Tool', 'Assets', 'Plugins', 'docs', 'packaging', 'tests', '.github', 'site', 'Cobros')
EXTENSIONS = {'.ps1', '.bat', '.cmd', '.md', '.json', '.xml', '.wxs', '.py', '.svg', '.ico', '.yml', '.yaml', '.txt', '.html', '.css', '.mjs', '.xls', '.xlsx'}
# Hojas de cálculo: solo los ejemplos ficticios del Analizador de cobros. Un Excel de clientes
# dejado junto al analizador no debe acabar en el autoextraíble versionado (repositorio público).
SPREADSHEETS = {'.xls', '.xlsx'}
SPREADSHEET_ALLOWLIST = re.compile(r'Cobros/ejemplo/cobros-ejemplo\.xls|tests/fixtures/cobros-[a-z0-9-]+\.xlsx?')


def allowed_spreadsheet(name):
    return pathlib.PurePosixPath(name).suffix.lower() not in SPREADSHEETS or bool(SPREADSHEET_ALLOWLIST.fullmatch(name))
EXCLUDED = {'__pycache__', '.git', '.venv', '.pytest_cache', 'artifacts', 'Releases', 'node_modules'}


def source_files():
    paths = [ROOT / name for name in ROOT_FILES]
    for tree in TREES:
        paths.extend(p for p in (ROOT / tree).rglob('*') if p.is_file() and (p.suffix.lower() in EXTENSIONS or p.name in {'CODEOWNERS', '.nojekyll'}))
    selected = []
    seen = set()
    for path in sorted(set(paths)):
        relative = path.relative_to(ROOT)
        if EXCLUDED.intersection(relative.parts) or not allowed_spreadsheet(relative.as_posix()):
            continue
        if any(parent.is_symlink() for parent in (path, *path.parents)):
            raise ValueError(f'No se empaquetan enlaces: {relative}')
        name = relative.as_posix()
        if len(name) > 180 or name.casefold() in seen:
            raise ValueError(f'Ruta larga o duplicada para Windows: {name}')
        for part in relative.parts:
            if part in {'.', '..'} or part.endswith(('.', ' ')) or re.search(r'[<>:"|?*\\\x00-\x1f]', part) or re.match(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)', part, re.I):
                raise ValueError(f'Nombre no valido para Windows: {name}')
        seen.add(name.casefold())
        selected.append(path)
    return selected


def build():
    metadata = json.loads((ROOT / 'VERSION.json').read_text(encoding='utf-8'))
    if metadata['version'] != '4.0.0':
        raise ValueError('Actualiza nombre, plantilla y version del bootstrap conjuntamente.')
    stream = io.BytesIO()
    records = []
    total = 0
    with zipfile.ZipFile(stream, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in source_files():
            data = path.read_bytes()
            total += len(data)
            if len(data) > 4194304 or total > 16777216:
                raise ValueError('Se excede el limite de extraccion.')
            name = path.relative_to(ROOT).as_posix()
            info = zipfile.ZipInfo(name, date_time=(2026, 11, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
            records.append({'path': name, 'size': len(data), 'sha256': hashlib.sha256(data).hexdigest().upper()})
    if len(records) > 512:
        raise ValueError('Demasiados archivos para la plantilla.')
    archive_bytes = stream.getvalue()
    index = json.dumps({'version': '4.0.0', 'files': records}, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
    template = (ROOT / 'packaging/Bootstrap.Template.ps1').read_text(encoding='utf-8-sig')
    def wrapped(data):
        encoded = base64.b64encode(data).decode('ascii')
        return '\n'.join(encoded[i:i+100] for i in range(0, len(encoded), 100))
    result = template.replace('__ARCHIVE_BASE64__', wrapped(archive_bytes)).replace('__INDEX_BASE64__', wrapped(index)).replace('__ARCHIVE_SHA256__', hashlib.sha256(archive_bytes).hexdigest().upper())
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(result, encoding='utf-8-sig', newline='\n')
    print(f'Creado {OUTPUT.relative_to(ROOT)}: {len(records)} archivos, {total} bytes originales, {OUTPUT.stat().st_size} bytes finales.')


if __name__ == '__main__':
    build()
