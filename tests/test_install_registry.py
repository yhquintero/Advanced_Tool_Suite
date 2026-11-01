"""Contratos del fix de escritura de registro; la ejecucion real se hace en CI Windows."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


def text(path):
    return (ROOT / path).read_text(encoding='utf-8-sig')


class InstallRegistryTests(unittest.TestCase):
    def test_registry_is_explicitly_opened_writable_and_closed(self):
        source = text('packaging/Deployment.Common.ps1')
        self.assertIn('CurrentUser.OpenSubKey($match.Groups[1].Value, $true)', source)
        self.assertIn('finally { $writableKey.Dispose() }', source)
        self.assertIn("'^HKCU:", source)
        self.assertNotIn('Set-Acl', source)

    def test_install_and_rollback_use_same_typed_writer(self):
        source = text('install.ps1')
        self.assertNotIn('$key.SetValue(', source)
        self.assertEqual(source.count('Set-ATSUserRegistryValue -Path $config.UninstallKey'), 4)
        for fragment in ('-Kind String', "-Name 'NoModify' -Value 1 -Kind DWord", "-Name 'NoRepair' -Value 1 -Kind DWord", '-Kind $oldRegistry[$name].Kind'):
            self.assertIn(fragment, source)

    def test_rollback_preserves_raw_expand_strings_and_empty_values(self):
        self.assertIn('RegistryValueOptions]::DoNotExpandEnvironmentNames', text('install.ps1'))
        common = text('packaging/Deployment.Common.ps1')
        self.assertIn('[AllowEmptyString()][string]$Name', common)
        self.assertIn('[AllowEmptyString()][AllowEmptyCollection()]$Value', common)

    def test_native_registry_regression_runs_under_both_windows_engines(self):
        workflow = text('.github/workflows/validate.yml')
        self.assertEqual(workflow.count('run: .\\tests\\Probar-Registro-Instalacion.ps1'), 2)
        native = text('tests/Probar-Registro-Instalacion.ps1')
        for marker in ('[guid]::NewGuid()', '-Kind DWord', '-Kind ExpandString', '-Kind MultiString', '-Kind Binary', 'finally', 'HKLM:'):
            self.assertIn(marker, native)


if __name__ == '__main__':
    unittest.main()
