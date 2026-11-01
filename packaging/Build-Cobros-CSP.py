#!/usr/bin/env python3
"""Actualiza o comprueba la CSP por hash del Analizador de cobros.

`Cobros/AnalizadorCobros.html` es un único archivo sin red: sus <script> y <style>
en línea se autorizan solo por SHA-256. Tras editar el HTML ejecuta:

    python packaging/Build-Cobros-CSP.py          # recalcula los hashes
    python packaging/Build-Cobros-CSP.py --check  # falla si la CSP no coincide
"""
import argparse
import base64
import hashlib
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
HTML = ROOT / 'Cobros' / 'AnalizadorCobros.html'
SCRIPT_RE = re.compile(r'<script(?:\s[^>]*)?>(.*?)</script>', re.S | re.I)
STYLE_RE = re.compile(r'<style(?:\s[^>]*)?>(.*?)</style>', re.S | re.I)
CSP_RE = re.compile(r'(<meta http-equiv="Content-Security-Policy" content=")([^"]*)(">)')


def digest(text):
    # El navegador normaliza CRLF/CR a LF antes de calcular el hash del contenido en línea.
    normalized = text.replace('\r\n', '\n').replace('\r', '\n')
    return "'sha256-" + base64.b64encode(hashlib.sha256(normalized.encode('utf-8')).digest()).decode('ascii') + "'"


def build_policy(html):
    scripts = [digest(body) for body in SCRIPT_RE.findall(html)]
    styles = [digest(body) for body in STYLE_RE.findall(html)]
    if not scripts or not styles:
        raise ValueError('El analizador debe contener sus scripts y estilos en línea.')
    return '; '.join([
        "default-src 'none'",
        'script-src ' + ' '.join(scripts),
        'style-src ' + ' '.join(styles),
        'img-src data: blob:',
        "font-src 'none'",
        "connect-src 'none'",
        "media-src 'none'",
        "object-src 'none'",
        "frame-src 'none'",
        "worker-src 'none'",
        "manifest-src 'none'",
        "base-uri 'none'",
        "form-action 'none'",
    ])


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--check', action='store_true', help='solo comprobar, sin escribir')
    args = parser.parse_args()
    raw = HTML.read_bytes().decode('utf-8')
    match = CSP_RE.search(raw)
    if not match:
        print('No se encontró la meta Content-Security-Policy en ' + str(HTML.relative_to(ROOT)), file=sys.stderr)
        return 1
    expected = build_policy(raw)
    if match.group(2) == expected:
        print('CSP del analizador sincronizada.')
        return 0
    if args.check:
        print('La CSP de Cobros/AnalizadorCobros.html no coincide con sus scripts/estilos. Ejecuta: python packaging/Build-Cobros-CSP.py', file=sys.stderr)
        return 1
    updated = raw[:match.start(2)] + expected + raw[match.end(2):]
    HTML.write_bytes(updated.encode('utf-8'))
    print('CSP actualizada en ' + str(HTML.relative_to(ROOT)))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
