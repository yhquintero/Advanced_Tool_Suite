"""Contratos de recursos, distribucion y seguridad de la version 3."""
import json
import pathlib
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'Tool/AdvancedToolSuite.ps1').read_text(encoding='utf-8-sig')


class Version3Tests(unittest.TestCase):
    def test_both_windows_have_well_formed_xaml(self):
        markups = re.findall(r"\[xml\]\$(?:xaml|preferencesXaml) = @'\n(.*?)\n'@", SOURCE, re.S)
        self.assertEqual(len(markups), 2)
        for markup in markups:
            root = ET.fromstring(markup)
            names = [v for e in root.iter() for k, v in e.attrib.items() if k.endswith('}Name')]
            self.assertEqual(len(names), len(set(names)))

    def test_42_svg_paths_match_embedded_geometry(self):
        embedded = SOURCE.split('$script:IconPaths = @{', 1)[1].split('\n}', 1)[0]
        paths = {int(i): d for i, d in re.findall(r"(\d+)='([^']+)'", embedded)}
        self.assertEqual(set(paths), set(range(1, 43)))
        self.assertEqual(len(set(paths.values())), 42)
        for i, d in paths.items():
            svg = ET.parse(ROOT / f'Assets/Icons/{i:02}.svg').getroot()
            self.assertEqual(svg.find('{http://www.w3.org/2000/svg}path').attrib['d'], d)

    def test_four_themes(self):
        for theme in ('Neon azul', 'Purpura cyberpunk', 'Verde Matrix', 'Rojo gaming'):
            self.assertIn(f"'{theme}'=@(", SOURCE)

    def test_favorites_are_sibling_controls_not_nested_buttons(self):
        self.assertIn('$wrapper.Children.Add($button)', SOURCE)
        self.assertIn('$wrapper.Children.Add($star)', SOURCE)
        self.assertNotIn('$top.Children.Add($star)', SOURCE)

    def test_readonly_uses_allowlist_and_blocks_admin_shell(self):
        body = re.search(r'function Test-ReadOnlyTool.*?return \$Id -in @\((.*?)\)', SOURCE).group(1)
        allowed = {int(i) for i in body.split(',')}
        self.assertEqual(allowed, {1, 11, 14, 19, 27, 28, 29, 30})
        self.assertIn('Assert-ToolAllowed $Tool', SOURCE)

    def test_undo_does_not_accept_persisted_paths(self):
        self.assertIn('Get-RegistrySpec ([int]$snapshot.Id)', SOURCE)
        self.assertNotIn('$snapshot.Path', SOURCE.replace('$snapshot.PathExisted', ''))
        self.assertIn('DoNotExpandEnvironmentNames', SOURCE)

    def test_guard_uses_dpapi_and_salted_pbkdf2(self):
        self.assertIn('310000', SOURCE)
        self.assertIn('HashAlgorithmName]::SHA256', SOURCE)
        self.assertIn('DataProtectionScope]::CurrentUser', SOURCE)
        self.assertIn('ZeroFreeBSTR', SOURCE)
        self.assertIn('LockedUntil', SOURCE)

    def test_restore_checks_new_point_before_dispatch(self):
        self.assertIn('-WarningAction Stop', SOURCE)
        self.assertIn('$after.Count -eq 0', SOURCE)
        self.assertIn('$pending.Process.ExitCode -eq 0', SOURCE)

    def test_structured_audit_and_retention(self):
        self.assertIn("'audit.jsonl'", SOURCE)
        self.assertIn("'C:\\REPORTE\\audit.log'", SOURCE)
        self.assertIn("'PROCESS_EXIT_ERROR'", SOURCE)
        self.assertIn('5242880', SOURCE)
        self.assertIn('utc=[DateTime]::UtcNow', SOURCE)

    def test_scheduled_task_is_limited_interactive_and_fixed(self):
        self.assertIn('-LogonType Interactive -RunLevel Limited', SOURCE)
        self.assertIn("'ATS-Informe-'", SOURCE)
        self.assertNotIn('-Password ', SOURCE)

    def test_portable_is_self_contained(self):
        self.assertNotRegex(SOURCE, r'(?m)^\s*\.\s+.*\.ps1')
        self.assertNotIn('__EXTENSIONS__', SOURCE)
        self.assertNotIn('__ICONS__', SOURCE)
        self.assertNotIn('ExecutionPolicy Bypass', SOURCE)

    def test_version_consistency(self):
        metadata = json.loads((ROOT / 'VERSION.json').read_text())
        self.assertIn(f"$script:Version = '{metadata['version']}'", SOURCE)
        self.assertIn(metadata['version'], (ROOT / 'CHANGELOG.md').read_text())
        self.assertEqual(len(metadata['features']), 20)
        self.assertEqual([f['id'] for f in metadata['features']], list(range(1, 21)))

    def test_msi_xml_and_user_scope(self):
        root = ET.parse(ROOT / 'packaging/Suite.wxs').getroot()
        ns = {'w': 'http://schemas.microsoft.com/wix/2006/wi'}
        self.assertEqual(root.find('w:Product/w:Package', ns).attrib['InstallScope'], 'perUser')
        self.assertIsNotNone(root.find('w:Product/w:MajorUpgrade', ns))
        self.assertIsNotNone(root.find('w:Product/w:Icon', ns))

    def test_build_does_not_download_or_elevate(self):
        build = (ROOT / 'packaging/Build-Release.ps1').read_text(encoding='utf-8-sig')
        self.assertNotIn('Install-Module', build)
        self.assertNotIn('-requireAdmin', build)
        self.assertIn('Get-FileHash', build)
        self.assertIn('if ($LASTEXITCODE -ne 0)', build)


if __name__ == '__main__':
    unittest.main()
