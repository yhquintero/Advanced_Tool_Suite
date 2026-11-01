"""Regresión de la web documental: catálogo fuente, anclas y recorridos locales."""
import collections
import html
from html.parser import HTMLParser
import importlib.util
import pathlib
import re
import subprocess
import sys
import unittest
from urllib.parse import unquote, urlsplit

ROOT = pathlib.Path(__file__).resolve().parents[1]
SITE = ROOT / 'site'
spec = importlib.util.spec_from_file_location('ats_site_catalog', ROOT / 'packaging/Build-Site-Catalog.py')
catalog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalog)


class Document(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.ids = []
        self.links = []
        self.tools = []
        self.h1 = 0
        self.feed(path.read_text(encoding='utf-8'))

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.append(attrs['id'])
        if tag == 'a' and 'href' in attrs:
            self.links.append(attrs['href'])
        if 'data-tool-id' in attrs:
            self.tools.append(int(attrs['data-tool-id']))
        if tag == 'h1':
            self.h1 += 1


class SiteCatalogTests(unittest.TestCase):
    def test_catalog_is_synchronized_without_writing(self):
        result = subprocess.run([sys.executable, str(ROOT / 'packaging/Build-Site-Catalog.py'), '--check'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_catalog_contains_each_of_42_source_ids_once(self):
        self.assertEqual(sorted(Document(SITE / 'index.html').tools), list(range(1, 43)))

    def test_catalog_matches_names_descriptions_and_categories(self):
        source = (SITE / 'index.html').read_text(encoding='utf-8')
        records = catalog.tools()
        self.assertEqual(len({r['category'] for r in records}), 6)
        self.assertEqual(source.count('class="category"'), 6)
        self.assertIn('<strong>6</strong><span>categorías de trabajo</span>', source)
        for record in records:
            self.assertIn(html.escape(record['name']), source)
            self.assertIn(html.escape(record['description']), source)

    def test_catalog_includes_permission_badges(self):
        for record in catalog.tools():
            rendered = catalog.render([record])
            expected = ('UAC · confirmar' if record['admin'] else 'Confirmación') if record['risk'] else ('UAC' if record['admin'] else 'Abrir / consultar')
            self.assertIn(expected, rendered)

    def test_all_pages_have_one_h1_and_unique_ids(self):
        for path in SITE.glob('*.html'):
            document = Document(path)
            self.assertEqual(document.h1, 1, path.name)
            repeated = [key for key, count in collections.Counter(document.ids).items() if count > 1]
            self.assertEqual(repeated, [], path.name)

    def test_local_anchors_resolve_including_cross_page_navigation(self):
        for path in SITE.glob('*.html'):
            for href in Document(path).links:
                url = urlsplit(href)
                if url.scheme or url.netloc:
                    continue
                relative = unquote(url.path).removeprefix('/Advanced_Tool_Suite/')
                if url.path.startswith('/Advanced_Tool_Suite/'):
                    target = (SITE / relative).resolve()
                else:
                    target = (path.parent / relative).resolve() if url.path else path.resolve()
                if target.is_dir():
                    target /= 'index.html'
                self.assertTrue(target.is_relative_to(SITE), (path.name, href))
                self.assertTrue(target.is_file(), (path.name, href))
                if url.fragment and target.suffix == '.html':
                    self.assertIn(unquote(url.fragment), Document(target).ids, (path.name, href))

    def test_github_source_links_reference_existing_files(self):
        for path in SITE.glob('*.html'):
            for href in Document(path).links:
                match = re.fullmatch(r'https://github\.com/yhquintero/Advanced_Tool_Suite/(?:blob|tree)/main/([^?#]+)(?:[?#].*)?', href)
                if match:
                    self.assertTrue((ROOT / unquote(match[1])).exists(), (path.name, href))

    def test_guide_documents_actual_bootstrap_flags_without_bypass(self):
        guide = (SITE / 'guia.html').read_text(encoding='utf-8')
        for flag in ('-ValidateOnly', '-Destination', '-WhatIf'):
            self.assertIn(flag, guide)
        self.assertNotIn('-ExecutionPolicy', guide)
        self.assertNotIn('Invoke-Expression', guide)
        self.assertIn('Tool\\Iniciar.cmd', guide)

    def test_conceptual_preview_and_security_limits_are_explicit(self):
        source = (SITE / 'index.html').read_text(encoding='utf-8')
        self.assertIn('role="img" aria-label="Ilustración', source)
        self.assertIn('no captura ni demo del programa', source)
        self.assertIn('no representan mediciones reales', source)
        self.assertIn('no desde esta web', source)
        security = (SITE / 'seguridad.html').read_text(encoding='utf-8')
        for limitation in ('no inmutables', 'frame-ancestors', 'no verifica la identidad', 'no sustituye una copia'):
            self.assertIn(limitation, security)

    def test_no_unfinished_placeholders(self):
        for path in SITE.glob('*.html'):
            self.assertNotIn('__CATALOG__', path.read_text(encoding='utf-8'), path.name)


if __name__ == '__main__':
    unittest.main()
