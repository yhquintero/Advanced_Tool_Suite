"""Pruebas del unico fichero autoextraible y de los contratos de plugins, sin Windows."""
import base64
import hashlib
import importlib.util
import io
import json
import pathlib
import re
import unittest
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]


def load_builder():
    spec = importlib.util.spec_from_file_location('ats_bootstrap_builder', ROOT / 'packaging/Build-Bootstrap.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class BootstrapTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.builder = load_builder()
        if not cls.builder.OUTPUT.exists():
            cls.builder.build()
        cls.source = cls.builder.OUTPUT.read_text(encoding='utf-8-sig')
        cls.payload = base64.b64decode(re.search(r"\$archiveBase64 = @'\n(.*?)\n'@", cls.source, re.S).group(1))
        cls.index = json.loads(base64.b64decode(re.search(r"\$indexBase64 = @'\n(.*?)\n'@", cls.source, re.S).group(1)))

    def test_archive_hash(self):
        expected = re.search(r"\$expectedArchiveHash = '([A-F0-9]{64})'", self.source).group(1)
        self.assertEqual(hashlib.sha256(self.payload).hexdigest().upper(), expected)

    def test_all_entries_match_index_hash_and_current_sources(self):
        expected = {item['path']: item for item in self.index['files']}
        with zipfile.ZipFile(io.BytesIO(self.payload)) as archive:
            self.assertEqual(set(archive.namelist()), set(expected))
            for path, item in expected.items():
                data = archive.read(path)
                self.assertEqual(len(data), item['size'], path)
                self.assertEqual(hashlib.sha256(data).hexdigest().upper(), item['sha256'], path)
                self.assertEqual(data, (ROOT / path).read_bytes(), f'Regenera el bootstrap: {path}')

    def test_complete_source_tree_is_included(self):
        expected = {path.relative_to(ROOT).as_posix() for path in self.builder.source_files()}
        self.assertEqual({f['path'] for f in self.index['files']}, expected)
        self.assertGreater(len(expected), 70)

    def test_no_git_caches_or_recursive_bootstrap(self):
        for item in self.index['files']:
            parts = pathlib.PurePosixPath(item['path']).parts
            self.assertFalse(set(parts) & {'.git', '__pycache__', 'artifacts', 'Releases'})

    def test_limits_and_windows_case_uniqueness(self):
        paths = [item['path'] for item in self.index['files']]
        self.assertEqual(len(paths), len({p.casefold() for p in paths}))
        self.assertLessEqual(sum(f['size'] for f in self.index['files']), 16777216)
        self.assertLessEqual(len(paths), 512)
        for path in paths:
            self.assertNotIn('..', pathlib.PurePosixPath(path).parts)
            self.assertNotRegex(path, r'(^/|\\|:)')

    def test_no_overwrite_bypass_or_automatic_execution(self):
        self.assertIn('Directory]::Move($stage,$target)', self.source)
        self.assertIn('if (Test-Path -LiteralPath $target)', self.source)
        self.assertNotIn('ExecutionPolicy Bypass', self.source)
        self.assertIn('if ($Launch -and $PSCmdlet.ShouldProcess', self.source)
        self.assertLess(self.source.index('if ($ValidateOnly)'), self.source.index('ShouldProcess($target'))
        self.assertLess(self.source.index('ShouldProcess($target'), self.source.index('Directory]::CreateDirectory($stage)'))

    def test_build_is_reproducible(self):
        previous = self.builder.OUTPUT.read_bytes()
        self.builder.build()
        self.assertEqual(previous, self.builder.OUTPUT.read_bytes())


class PluginTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = (ROOT / 'Plugins/Plugin.Core.ps1').read_text(encoding='utf-8-sig')
        cls.main = (ROOT / 'Tool/AdvancedToolSuite.ps1').read_text(encoding='utf-8-sig')

    def test_core_is_embedded_exactly(self):
        embedded = self.main.split('# REGION ATS_PLUGIN_CORE\n', 1)[1].split('\n# ENDREGION ATS_PLUGIN_CORE', 1)[0]
        self.assertEqual(embedded.rstrip(), self.core.rstrip())

    def test_examples_follow_schema_shape_and_safe_actions(self):
        schema = json.loads((ROOT / 'Plugins/plugin.schema.json').read_text())
        for path in (ROOT / 'Plugins/Examples').glob('*.json'):
            plugin = json.loads(path.read_text())
            self.assertEqual(set(plugin), set(schema['required']))
            self.assertEqual(plugin['id'], path.stem)
            self.assertRegex(plugin['id'], schema['properties']['id']['pattern'])
            self.assertIn(plugin['toolId'], schema['properties']['toolId']['enum'])
            self.assertIn(plugin['toolId'], {1, 14, 19, 27, 28, 30})

    def test_plugins_never_evaluate_external_commands(self):
        for forbidden in ('Invoke-Expression', '[ScriptBlock]::Create', 'Start-Process', 'Add-Type', '.psm1'):
            self.assertNotIn(forbidden, self.core)
        self.assertIn('Invoke-Tool $tool[0]', self.core)
        self.assertIn('$fields -cnotcontains $_', self.core)

    def test_explicit_approval_and_revalidation(self):
        self.assertIn("'PLUGIN_IMPORTED'", self.core)
        self.assertIn('EnabledPlugins', self.core)
        self.assertIn('Get-ATSPlugins | Where-Object', self.core)
        self.assertIn('$_.Hash -ceq $Record.Hash -and $_.Enabled', self.core)
        self.assertIn('FileMode]::CreateNew', self.core)

    def test_readonly_blocks_plugin_store_changes(self):
        self.assertIn("$script:Settings.ReadOnly", self.core)
        self.assertLess(self.core.index("$operation -eq 'Ejecutar'"), self.core.index('$script:Settings.ReadOnly'))


if __name__ == '__main__':
    unittest.main()
