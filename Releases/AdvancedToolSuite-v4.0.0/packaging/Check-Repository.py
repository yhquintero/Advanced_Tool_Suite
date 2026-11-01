#!/usr/bin/env python3
"""Comprobaciones locales sin red: enlaces, web pasiva, acciones fijadas y patrones de secretos.
No sustituye una auditoria ni un escaner completo de credenciales.
"""
from __future__ import annotations
import json
import pathlib
import re
import sys
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXCLUDED = {'.git', '__pycache__', '.venv', 'artifacts', 'node_modules', 'Releases', '.pytest_cache'}
SECRET_PATTERNS = (
    re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    re.compile(r'\bgh[pousr]_[A-Za-z0-9]{36,}\b'),
    re.compile(r'\bgithub_pat_[A-Za-z0-9_]{60,}\b'),
    re.compile(r'\bAKIA[0-9A-Z]{16}\b'),
)


def markdown_issues(path):
    issues = []
    content = path.read_text(encoding='utf-8-sig')
    for match in re.finditer(r'!?\[[^\]\n]*\]\(([^\s)]+)(?:\s+"[^"]*")?\)', content):
        link = match.group(1)
        parsed = urlsplit(link)
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        target = (path.parent / unquote(parsed.path)).resolve()
        if not target.is_relative_to(ROOT) or not target.exists():
            issues.append(f'{path.relative_to(ROOT)}: enlace local inexistente o fuera del proyecto: {link}')
    return issues


class PassiveSiteParser(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.path = path
        self.issues = []
        self.has_csp = False
        self.has_lang = False
        self.has_title = False
        self.has_viewport = False

    def handle_starttag(self, tag, attrs):
        attr = dict(attrs)
        if tag == 'html':
            self.has_lang = attr.get('lang') == 'es'
        if tag == 'title':
            self.has_title = True
        if tag == 'meta':
            self.has_viewport |= attr.get('name') == 'viewport'
            if attr.get('http-equiv', '').lower() == 'content-security-policy':
                policy = attr.get('content', '')
                self.has_csp = all(rule in policy for rule in ("default-src 'none'", "script-src 'none'", "object-src 'none'", "base-uri 'none'", "form-action 'none'"))
        if tag in {'script', 'iframe', 'form', 'object', 'embed', 'base', 'style'}:
            self.issues.append(f'elemento no permitido en web pasiva: {tag}')
        if any(name.startswith('on') or name == 'style' for name in attr):
            self.issues.append('evento o estilo inline no permitido')
        for key in ('href', 'src'):
            value = attr.get(key, '')
            if not value or value.startswith('#'):
                continue
            parsed = urlsplit(value)
            if parsed.scheme or parsed.netloc:
                if tag != 'a' or parsed.scheme != 'https' or parsed.hostname != 'github.com':
                    self.issues.append('recurso remoto o enlace externo no aprobado')
            else:
                # La 404 usa el prefijo del proyecto para conservar el enlace en rutas anidadas.
                prefix = '/Advanced_Tool_Suite/'
                target = (ROOT / 'site' / value[len(prefix):]) if value.startswith(prefix) else (self.path.parent / unquote(parsed.path))
                if not target.resolve().is_relative_to(ROOT / 'site') or not target.exists():
                    self.issues.append(f'recurso local inexistente: {value}')
        if attr.get('target') == '_blank' and 'noopener' not in attr.get('rel', '').split():
            self.issues.append('enlace con target=_blank sin noopener')


def site_issues(path):
    parser = PassiveSiteParser(path)
    parser.feed(path.read_text(encoding='utf-8'))
    if not all((parser.has_csp, parser.has_lang, parser.has_title, parser.has_viewport)):
        parser.issues.append('faltan CSP restrictiva, lang=es, title o viewport')
    return [f'{path.relative_to(ROOT)}: {item}' for item in parser.issues]


def check():
    issues = []
    metadata = json.loads((ROOT / '.github/repository.json').read_text())
    if not 1 <= len(metadata['description']) <= 350:
        issues.append('About debe tener entre 1 y 350 caracteres')
    for path in ROOT.rglob('*'):
        if not path.is_file() or EXCLUDED.intersection(path.relative_to(ROOT).parts):
            continue
        if path.suffix.lower() in {'.pfx', '.p12', '.key', '.pem'} or path.name == '.env':
            issues.append(f'{path.relative_to(ROOT)}: archivo sensible no permitido')
        if path.suffix.lower() == '.md':
            issues.extend(markdown_issues(path))
        if path.parent == ROOT / '.github/workflows' and path.suffix in {'.yml', '.yaml'}:
            source = path.read_text()
            if 'pull_request_target' in source or 'write-all' in source:
                issues.append(f'{path.name}: evento o permisos demasiado amplios')
            for use in re.findall(r'\buses:\s*([^\s#]+)', source):
                if not re.fullmatch(r'[\w.-]+/[\w./-]+@[a-f0-9]{40}', use):
                    issues.append(f'{path.name}: accion sin SHA completo: {use}')
        if path.suffix.lower() in {'.md', '.py', '.ps1', '.json', '.yml', '.yaml', '.txt', '.html'}:
            source = path.read_text(encoding='utf-8-sig', errors='replace')
            for pattern in SECRET_PATTERNS:
                if pattern.search(source):
                    issues.append(f'{path.relative_to(ROOT)}: patron de secreto detectado (valor omitido)')
    for path in (ROOT / 'site').glob('*.html'):
        issues.extend(site_issues(path))
    if issues:
        print('\n'.join(issues), file=sys.stderr)
        return 1
    print('Repositorio verificado: enlaces locales, web pasiva, acciones fijadas, About y patrones basicos de secretos.')
    return 0


if __name__ == '__main__':
    raise SystemExit(check())
