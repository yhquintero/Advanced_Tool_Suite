"""Regresiones estaticas del arranque de instalacion desde fuentes (sin ejecutar Windows)."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


def read(name):
    return (ROOT / name).read_text(encoding='utf-8-sig')


class SourceInstallTests(unittest.TestCase):
    def test_build_requires_recognized_local_sources(self):
        source = read('install.ps1')
        for fragment in ('$source -eq $PSScriptRoot', "'SHA256.json'", "'Tool\\AdvancedToolSuite.ps1'", 'if ($isSourceTree)'):
            self.assertIn(fragment, source)
        self.assertLess(source.index('if ($isSourceTree)'), source.index('$package = Assert-ATSPackage'))

    def test_whatif_returns_before_builder_can_write(self):
        source = read('install.ps1')
        guard = "if (-not $PSCmdlet.ShouldProcess($prepared,"
        self.assertIn(guard, source)
        self.assertLess(source.index(guard), source.index('& $windowsPowerShell'))
        self.assertIn("instalar')) { return }", source)

    def test_signature_policy_and_build_failure_remain_fail_closed(self):
        source = read('install.ps1')
        self.assertLess(source.index('if ($RequireSignature)'), source.index('& $windowsPowerShell'))
        self.assertIn('if ($LASTEXITCODE -ne 0) { throw', source)
        self.assertIn('Assert-ATSPackage $source -RequireSignature:$RequireSignature', source)
        self.assertIn('Assert-ATSPackage $stage -RequireSignature:$RequireSignature', source)

    def test_unique_build_uses_supported_engine_without_policy_bypass(self):
        source = read('install.ps1')
        self.assertIn('Portable-install-', source)
        self.assertIn('[guid]::NewGuid()', source)
        self.assertIn('System32\\WindowsPowerShell\\v1.0\\powershell.exe', source)
        self.assertIn('-Format Portable -OutputDirectory $prepared', source)
        self.assertNotIn('ExecutionPolicy', source)
        builder = read('packaging/Build-Release.ps1')
        self.assertIn('[string]$OutputDirectory', builder)
        self.assertIn('Get-ChildItem $out -Force', builder)
        self.assertIn('para evitar archivos obsoletos', builder)

    def test_native_regression_is_in_ci(self):
        self.assertIn('Probar-Instalacion-Fuentes.ps1', read('.github/workflows/validate.yml'))
        native = read('tests/Probar-Instalacion-Fuentes.ps1')
        for fragment in ('-WhatIf', '-OutputDirectory', 'Assert-ATSPackage', 'alterado'):
            self.assertIn(fragment, native)


if __name__ == '__main__':
    unittest.main()
