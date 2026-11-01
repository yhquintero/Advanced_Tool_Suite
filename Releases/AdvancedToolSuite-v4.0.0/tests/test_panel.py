"""Contratos estaticos; no ejecuta acciones administrativas ni requiere Windows."""
import pathlib
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'Tool' / 'AdvancedToolSuite.ps1'
SOURCE = SCRIPT.read_text(encoding='utf-8-sig')


class PanelTests(unittest.TestCase):
    def test_catalog_has_42_unique_tools(self):
        ids = [int(x) for x in re.findall(r'@\{Id=(\d+);', SOURCE)]
        self.assertEqual(sorted(ids), list(range(1, 43)))

    def test_all_ids_have_dispatch(self):
        dispatch = SOURCE.split('switch ($Tool.Id) {', 1)[1].split('default {', 1)[0]
        ids = {int(x) for x in re.findall(r'^\s+(\d+) \{', dispatch, re.M)}
        grouped = re.search(r'\$_ -in ([\d,]+)', dispatch)
        ids.update(int(x) for x in grouped.group(1).split(','))
        self.assertEqual(ids, set(range(1, 43)))

    def test_xaml_is_well_formed_and_named_controls_exist(self):
        markup = re.search(r"\[xml\]\$xaml = @'\n(.*?)\n'@", SOURCE, re.S).group(1)
        root = ET.fromstring(markup)
        ns = '{http://schemas.microsoft.com/winfx/2006/xaml}'
        names = [element.attrib[ns + 'Name'] for element in root.iter() if ns + 'Name' in element.attrib]
        self.assertEqual(len(names), len(set(names)))
        expected = {'Navigation', 'Refresh', 'Machine', 'Session', 'Search', 'Count', 'Cards', 'Empty', 'Activity', 'OpenLog'}
        self.assertTrue(expected.issubset(names))
        self.assertIn('CornerRadius="16"', markup)

    def test_launcher_uses_sta_and_relative_path(self):
        launcher = (ROOT / 'Tool' / 'Iniciar.cmd').read_text()
        self.assertIn('-NoProfile -STA -File "%~dp0AdvancedToolSuite.ps1"', launcher)
        self.assertNotIn('Bypass', launcher)

    def test_windows_powershell_encoding(self):
        self.assertTrue(SCRIPT.read_bytes().startswith(b'\xef\xbb\xbf'))

    def test_validation_runs_before_windows_dependencies(self):
        self.assertLess(SOURCE.index('if ($ValidateOnly)'), SOURCE.index('Add-Type -AssemblyName'))

    def test_no_forced_shutdown_or_command_evaluation(self):
        self.assertNotIn('Invoke-Expression', SOURCE)
        self.assertNotIn("'/s /t 60'", SOURCE)
        self.assertNotIn("'/r /t 60'", SOURCE)
        self.assertIn("'/s /t 0'", SOURCE)
        self.assertIn("'/r /t 0'", SOURCE)


if __name__ == '__main__':
    unittest.main()
