"""Pruebas del Analizador de cobros (Cobros/AnalizadorCobros.html).

El analizador es un único HTML sin red que lee el Excel del usuario dentro del navegador.
Estas pruebas comprueban su aislamiento (CSP por hash, sin URLs ni APIs de red, sin
inyección de HTML) y ejecutan las pruebas del núcleo con Node.js si está disponible.
"""
import importlib.util
import pathlib
import re
import shutil
import subprocess
import sys
import unittest
from html.parser import HTMLParser

ROOT = pathlib.Path(__file__).resolve().parents[1]
HTML = ROOT / 'Cobros' / 'AnalizadorCobros.html'
HARNESS = ROOT / 'tests' / 'cobros-harness.mjs'
SVG_NS = 'http://www.w3.org/2000/svg'


class MarkupAudit(HTMLParser):
    def __init__(self):
        super().__init__()
        self.handlers = []
        self.inline_styles = []
        self.external = []
        self.scripts = []

    def handle_starttag(self, tag, attrs):
        attr = dict(attrs)
        for name, _ in attrs:
            if name.startswith('on'):
                self.handlers.append(f'<{tag} {name}>')
            if name == 'style':
                self.inline_styles.append(tag)
        if tag == 'script':
            self.scripts.append(attr.get('id'))
            if 'src' in attr:
                self.external.append(f'script src={attr["src"]}')
        if tag == 'link':
            self.external.append(f'link href={attr.get("href")}')
        for name in ('src', 'href', 'action', 'formaction', 'poster', 'data'):
            value = attr.get(name) or ''
            if re.match(r'\s*(https?:|//|javascript:)', value, re.I):
                self.external.append(f'{tag} {name}={value}')


class CobrosStaticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.html = HTML.read_text(encoding='utf-8')
        cls.scripts = re.findall(r'<script(?:\s[^>]*)?>(.*?)</script>', cls.html, re.S | re.I)
        cls.code = '\n'.join(cls.scripts)

    def csp(self):
        match = re.search(r'<meta http-equiv="Content-Security-Policy" content="([^"]*)">', self.html)
        self.assertIsNotNone(match, 'falta la CSP en <meta>')
        return dict((part.strip().split(' ', 1) + [''])[:2] for part in match.group(1).split(';') if part.strip())

    def test_csp_blocks_network_and_only_allows_hashed_inline_code(self):
        policy = self.csp()
        self.assertEqual(policy['default-src'], "'none'")
        for directive in ('connect-src', 'font-src', 'object-src', 'frame-src', 'worker-src', 'base-uri', 'form-action', 'media-src', 'manifest-src'):
            self.assertEqual(policy.get(directive), "'none'", directive)
        self.assertEqual(policy['img-src'], 'data: blob:')
        for directive in ('script-src', 'style-src'):
            sources = policy[directive].split()
            self.assertTrue(sources, directive)
            self.assertTrue(all(re.fullmatch(r"'sha256-[A-Za-z0-9+/]{43}='", s) for s in sources), f'{directive} solo admite hashes: {sources}')
        self.assertEqual(len(policy['script-src'].split()), len(self.scripts))
        self.assertIn('<meta name="referrer" content="no-referrer">', self.html)

    def test_csp_hashes_match_inline_code(self):
        result = subprocess.run([sys.executable, str(ROOT / 'packaging' / 'Build-Cobros-CSP.py'), '--check'], capture_output=True, text=True, cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_markup_has_no_handlers_inline_styles_or_external_resources(self):
        audit = MarkupAudit()
        audit.feed(self.html)
        self.assertEqual(audit.handlers, [])
        self.assertEqual(audit.inline_styles, [])
        self.assertEqual(audit.external, [])
        self.assertEqual(audit.scripts, ['cobros-core', 'cobros-ui'])

    def test_scripts_have_no_network_or_dynamic_code(self):
        forbidden = {
            'fetch(': r'\bfetch\s*\(', 'XMLHttpRequest': r'XMLHttpRequest', 'WebSocket': r'\bWebSocket\b', 'EventSource': r'\bEventSource\b',
            'sendBeacon': r'sendBeacon', 'importScripts': r'importScripts', 'import(': r'\bimport\s*\(', 'eval': r'\beval\s*\(',
            'new Function': r'new\s+Function\b', 'setTimeout con texto': r'set(?:Timeout|Interval)\s*\(\s*[\'"`]', 'window.open': r'window\.open\s*\(',
            'innerHTML': r'\.innerHTML\b', 'outerHTML': r'\.outerHTML\b', 'insertAdjacentHTML': r'insertAdjacentHTML', 'document.write': r'document\.write',
            'createContextualFragment': r'createContextualFragment', 'srcdoc': r'\bsrcdoc\b', 'postMessage': r'postMessage',
        }
        for label, pattern in forbidden.items():
            self.assertIsNone(re.search(pattern, self.code), f'API no permitida en el analizador: {label}')
        urls = set(re.findall(r'(?:https?:)?//[A-Za-z0-9.-]+\.[a-z]{2,}[^\s\'"`)]*', self.code))
        self.assertEqual(urls - {SVG_NS}, set(), 'el código no debe contener URLs')

    def test_inline_scripts_cannot_break_out_of_their_element(self):
        for body in self.scripts:
            for token in ('</script', '<script', '<!--'):
                self.assertNotIn(token, body.lower())

    def test_data_is_never_persisted(self):
        stores = re.findall(r'localStorage\.(?:setItem|getItem|removeItem)\(\s*([A-Za-z_$][\w$]*|\'[^\']*\')', self.code)
        self.assertTrue(stores, 'se esperaba persistencia solo de ajustes')
        self.assertIn("var SETTINGS_KEY = 'nexus-cobros-ajustes-v1'", self.code)
        self.assertEqual(set(stores), {'SETTINGS_KEY'})
        for api in ('sessionStorage', 'indexedDB', 'document.cookie', 'caches.open', 'serviceWorker'):
            self.assertNotIn(api, self.code)

    def test_spanish_interface_covers_the_requested_analysis(self):
        for text in ('Contribuyente', 'Importe ($)', 'Fecha de pago', 'No pagaron', 'Fuera de plazo', 'Gráficos dinámicos',
                     'días hábiles', 'Cuba (oficiales y Viernes Santo)', 'Exportar CSV', '100 % local'):
            self.assertIn(text, self.html)
        self.assertIn('<html lang="es"', self.html)

    def test_sample_files_are_real_spreadsheets(self):
        xls = ROOT / 'Cobros' / 'ejemplo' / 'cobros-ejemplo.xls'
        self.assertEqual(xls.read_bytes()[:8], bytes.fromhex('D0CF11E0A1B11AE1'))
        self.assertEqual((ROOT / 'tests' / 'fixtures' / 'cobros-sst-continue.xls').read_bytes()[:8], bytes.fromhex('D0CF11E0A1B11AE1'))
        self.assertEqual((ROOT / 'tests' / 'fixtures' / 'cobros-ejemplo.xlsx').read_bytes()[:4], b'PK\x03\x04')
        self.assertLess(xls.stat().st_size, 256 * 1024)

    @unittest.skipUnless(shutil.which('git') and (ROOT / '.git').exists(), 'git no disponible')
    def test_client_spreadsheets_are_ignored_by_git(self):
        def ignored(path):
            return subprocess.run(['git', 'check-ignore', '-q', '--no-index', path], cwd=ROOT).returncode == 0
        for path in ('Cobros/clientes.xls', 'Cobros/Cobros 2026.xlsx', 'cobros.csv', 'docs/pagos.ods', 'Datos/registro.xlsm', 'Cobros/ejemplo/otro.xls'):
            self.assertTrue(ignored(path), f'{path} debería estar ignorado')
        for path in ('Cobros/ejemplo/cobros-ejemplo.xls', 'tests/fixtures/cobros-ejemplo.xlsx', 'tests/fixtures/cobros-sst-continue.xls'):
            self.assertFalse(ignored(path), f'{path} debe poder versionarse')

    def test_bootstrap_only_packages_fictional_spreadsheets(self):
        spec = importlib.util.spec_from_file_location('ats_bootstrap_builder_cobros', ROOT / 'packaging' / 'Build-Bootstrap.py')
        builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(builder)
        for name in ('Cobros/clientes.xls', 'Cobros/Cobros 2026.xlsx', 'Cobros/ejemplo/real.xls', 'tests/fixtures/pagos.xls', 'Cobros/ejemplo/cobros-ejemplo.xlsx'):
            self.assertFalse(builder.allowed_spreadsheet(name), name)
        for name in ('Cobros/ejemplo/cobros-ejemplo.xls', 'tests/fixtures/cobros-ejemplo.xlsx', 'tests/fixtures/cobros-sst-continue.xls', 'Cobros/AnalizadorCobros.html'):
            self.assertTrue(builder.allowed_spreadsheet(name), name)
        packaged = {p.relative_to(ROOT).as_posix() for p in builder.source_files()}
        self.assertIn('Cobros/AnalizadorCobros.html', packaged)
        self.assertIn('tests/cobros-harness.mjs', packaged)
        spreadsheets = {p for p in packaged if p.lower().endswith(('.xls', '.xlsx', '.xlsm', '.csv', '.ods'))}
        self.assertEqual(spreadsheets, {'Cobros/ejemplo/cobros-ejemplo.xls', 'tests/fixtures/cobros-ejemplo.xlsx', 'tests/fixtures/cobros-sst-continue.xls'})

    def test_guide_documents_privacy_and_rule(self):
        guide = (ROOT / 'Cobros' / 'README.md').read_text(encoding='utf-8')
        for text in ('AnalizadorCobros.html', '10 días hábiles', 'Viernes Santo', 'no sale de tu equipo', 'repositorio es público', 'Contribuyente', 'Importe ($)'):
            self.assertIn(text, guide)


def node_major():
    node = shutil.which('node')
    if not node:
        return 0
    try:
        out = subprocess.run([node, '--version'], capture_output=True, text=True, timeout=20).stdout
        return int(re.match(r'v(\d+)', out).group(1))
    except (OSError, ValueError, AttributeError, subprocess.SubprocessError):
        return 0


@unittest.skipUnless(node_major() >= 18, 'Node.js >= 18 no disponible')
class CobrosCoreTests(unittest.TestCase):
    def test_core_logic_with_node_harness(self):
        result = subprocess.run([shutil.which('node'), str(HARNESS)], capture_output=True, text=True, encoding='utf-8', timeout=300, cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertRegex(result.stdout, r'\d+ correctas, 0 fallos')


if __name__ == '__main__':
    unittest.main()
