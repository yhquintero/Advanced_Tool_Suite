"""Contratos de presentacion y seguridad de repositorio/web, sin red ni cambios GitHub."""
import importlib.util
import json
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('ats_repo_check', ROOT / 'packaging/Check-Repository.py')
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class RepositoryWebTests(unittest.TestCase):
    def test_about_is_within_350_characters(self):
        meta = json.loads((ROOT / '.github/repository.json').read_text(encoding='utf-8'))
        self.assertEqual(len(meta['description']), 255)
        self.assertLessEqual(len(meta['description']), 350)
        self.assertIn('github.com/yhquintero/Advanced_Tool_Suite#readme', meta['homepage'])

    def test_local_markdown_links(self):
        for path in ROOT.rglob('*.md'):
            if not checker.EXCLUDED.intersection(path.relative_to(ROOT).parts):
                self.assertEqual(checker.markdown_issues(path), [], str(path))

    def test_site_html_has_passive_policy_and_local_resources(self):
        for path in (ROOT / 'site').glob('*.html'):
            self.assertEqual(checker.site_issues(path), [])

    def test_checker_rejects_active_html(self):
        parser = checker.PassiveSiteParser(ROOT / 'site/index.html')
        parser.feed('<script src="https://evil.invalid/code.js"></script><form><input></form>')
        self.assertTrue(parser.issues)

    def test_checker_rejects_event_handlers_and_remote_images(self):
        parser = checker.PassiveSiteParser(ROOT / 'site/index.html')
        parser.feed('<img src="https://evil.invalid/track" onerror="bad()">')
        self.assertGreaterEqual(len(parser.issues), 2)

    def test_css_has_responsive_and_reduced_motion_rules(self):
        css = (ROOT / 'site/styles.css').read_text()
        self.assertIn('prefers-reduced-motion', css)
        self.assertIn(':focus-visible', css)
        self.assertIn('@media(max-width:', css)
        self.assertNotIn('@import', css)
        self.assertNotRegex(css, r'url\(\s*[\'"]?https?://')

    def test_actions_are_immutable_and_not_privileged_pr(self):
        for path in (ROOT / '.github/workflows').glob('*.yml'):
            source = path.read_text()
            self.assertNotIn('pull_request_target', source)
            self.assertNotIn('write-all', source)
            for action in re.findall(r'\buses:\s*([^\s#]+)', source):
                self.assertRegex(action, r'^[\w.-]+/[\w./-]+@[a-f0-9]{40}$')

    def test_pages_deployment_is_manual_and_main_only(self):
        source = (ROOT / '.github/workflows/pages.yml').read_text()
        self.assertIn('workflow_dispatch:', source)
        self.assertNotIn('push:', source)
        self.assertNotIn('pull_request:', source)
        self.assertIn("github.ref == 'refs/heads/main'", source)
        self.assertLess(source.index('  deploy:'), source.index('pages: write'))

    def test_checkout_does_not_persist_credentials(self):
        source = (ROOT / '.github/workflows/validate.yml').read_text()
        self.assertEqual(source.count('actions/checkout@'), source.count('persist-credentials: false'))
        self.assertIn('contents: read', source)
        self.assertIn('timeout-minutes:', source)

    def test_license_is_canonical_and_translation_is_separate(self):
        license_text = (ROOT / 'LICENSE').read_text()
        self.assertTrue(license_text.startswith('MIT License\n'))
        self.assertIn('Permission is hereby granted, free of charge', license_text)
        self.assertIn('SOFTWARE IS PROVIDED "AS IS"', license_text)
        self.assertTrue((ROOT / 'LICENSE.es.md').exists())

    def test_patterns_identify_synthetic_private_key_marker(self):
        marker = '-----' + 'BEGIN OPENSSH ' + 'PRIVATE KEY-----'
        self.assertTrue(any(pattern.search(marker) for pattern in checker.SECRET_PATTERNS))
        self.assertFalse(any(pattern.search('documentacion sin secretos') for pattern in checker.SECRET_PATTERNS))

    def test_security_policy_does_not_claim_absolute_security(self):
        source = (ROOT / 'SECURITY.md').read_text()
        self.assertIn('Ningún control proporciona seguridad completa', source)
        self.assertIn('403', source)
        self.assertIn('No publiques', source)

    def test_metadata_script_is_preview_by_default(self):
        source = (ROOT / 'packaging/Configure-Repository.ps1').read_text(encoding='utf-8-sig')
        self.assertIn('SupportsShouldProcess', source)
        self.assertIn('if (-not $Apply)', source)
        self.assertIn('$LASTEXITCODE -ne 0', source)
        self.assertLess(source.index('if (-not $Apply)'), source.index('& gh @arguments'))


if __name__ == '__main__':
    unittest.main()
