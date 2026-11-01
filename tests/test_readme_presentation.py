"""Contratos de la portada GitHub y su documentacion publica."""
import pathlib
import re
import unittest
from urllib.parse import unquote
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]


class ReadmePresentationTests(unittest.TestCase):
    def test_readme_navigation_matches_real_headings(self):
        source = (ROOT / 'README.md').read_text(encoding='utf-8')
        headings = set()
        for heading in re.findall(r'^#{1,6} (.+)$', source, re.M):
            headings.add(re.sub(r'[^\w\- ]', '', heading.lower()).replace(' ', '-'))
        for fragment in re.findall(r'\]\(#([^)]*)\)', source):
            self.assertIn(unquote(fragment), headings)

    def test_banner_is_original_local_passive_svg(self):
        path = ROOT / 'site/assets/nexus-overview.svg'
        root = ET.fromstring(path.read_text())
        tags = {e.tag.rsplit('}', 1)[-1] for e in root.iter()}
        self.assertFalse(tags.intersection({'script', 'foreignObject', 'image', 'use'}))
        self.assertIn('title', tags)
        self.assertIn('desc', tags)
        for element in root.iter():
            self.assertFalse(any(key.lower().startswith('on') for key in element.attrib))
        self.assertIn('site/assets/nexus-overview.svg', (ROOT / 'README.md').read_text())

    def test_language_summaries_are_actual_documents_not_ui_claims(self):
        english = (ROOT / 'docs/readme/README_en.md').read_text()
        portuguese = (ROOT / 'docs/readme/README_pt-BR.md').read_text()
        self.assertIn('not an English UI', english)
        self.assertIn('não uma interface em português', portuguese)
        for source in (english, portuguese):
            self.assertIn('-WhatIf', source)
            self.assertIn('5.1', source)
            self.assertIn('../../LICENSE', source)

    def test_installed_use_has_a_real_local_guide(self):
        source = (ROOT / 'site/uso.html').read_text()
        self.assertIn('Inicio → Advanced Tool Suite', source)
        self.assertIn('-NoProfile -STA -File', source)
        self.assertIn('Solo lectura', source)
        self.assertIn('href="uso.html"', (ROOT / 'site/index.html').read_text())
        readme = (ROOT / 'README.md').read_text()
        self.assertNotIn('no sobre el repositorio sin construir', readme)
        self.assertIn('publicación en GitHub Pages sigue pendiente', readme)


if __name__ == '__main__':
    unittest.main()
