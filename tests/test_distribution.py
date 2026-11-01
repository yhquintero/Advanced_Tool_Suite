"""Validaciones estaticas portables de la entrega 3.0.1 (no ejecutan instaladores)."""
import json
import pathlib
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]


def text(path):
    return (ROOT / path).read_text(encoding='utf-8-sig')


class DistributionTests(unittest.TestCase):
    def test_pester_has_exactly_43_numbered_cases(self):
        ids = re.findall(r"(?m)^\s+It '(\d+) -", text('tests/ATS.Tests.ps1'))
        self.assertEqual([int(i) for i in ids], list(range(1, 44)))
        self.assertNotIn('-Skip', text('tests/ATS.Tests.ps1'))

    def test_runner_enforces_count_and_writes_report(self):
        source = text('tests/Run-Pester.ps1')
        for fragment in ('TotalCount -ne 43', 'PassedCount -ne 43', 'SkippedCount -gt 0', 'NUnitXml', 'ATS-Pester.xml'):
            self.assertIn(fragment, source)

    def test_manifest_is_least_privilege(self):
        root = ET.fromstring(text('packaging/manifest.xml'))
        level = root.find('.//{urn:schemas-microsoft-com:asm.v3}requestedExecutionLevel')
        self.assertEqual(level.attrib, {'level': 'asInvoker', 'uiAccess': 'false'})

    def test_manifest_version_matches_metadata(self):
        root = ET.fromstring(text('packaging/manifest.xml'))
        identity = root.find('{urn:schemas-microsoft-com:asm.v1}assemblyIdentity')
        self.assertEqual(identity.attrib['version'], json.loads(text('VERSION.json'))['version'] + '.0')

    def test_manifest_embedded_before_signature_and_hashes(self):
        source = text('packaging/Build-Release.ps1')
        self.assertLess(source.index('& mt.exe'), source.index("'Sign-Release.ps1'"))
        self.assertLess(source.index("'Sign-Release.ps1'"), source.index('$checksums ='))
        self.assertIn('-inputresource:', source)

    def test_deployment_scripts_use_shouldprocess(self):
        for file in ('install.ps1', 'uninstall.ps1'):
            source = text(file)
            self.assertIn('SupportsShouldProcess', source)
            self.assertIn('$PSCmdlet.ShouldProcess', source)
            self.assertNotIn('ExecutionPolicy', source)
        source = text('install.ps1')
        self.assertLess(source.index('$PSCmdlet.ShouldProcess'), source.index('New-Item $parent'))

    def test_uninstall_does_not_recursively_delete_application_root(self):
        source = text('uninstall.ps1')
        self.assertNotRegex(source, r'Remove-Item[^\n]*\$config.Root[^\n]*-Recurse')
        self.assertIn('Read-ATSReceipt $config.Root', source)
        self.assertIn('Get-ChildItem -LiteralPath $config.Root', source)

    def test_payload_is_strictly_allowlisted(self):
        source = text('packaging/Deployment.Common.ps1')
        self.assertIn('$file.Name -notin (Get-ATSPayloadNames)', source)
        self.assertIn('$file.file -notin (Get-ATSPayloadNames)', source)
        self.assertIn('IO.FileAttributes]::ReparsePoint', source)
        self.assertIn("Algorithm SHA256", source)

    def test_staged_payload_is_revalidated(self):
        self.assertIn('Assert-ATSPackage $stage -RequireSignature:$RequireSignature', text('install.ps1'))

    def test_signing_never_imports_or_generates_private_keys(self):
        source = text('packaging/Sign-Release.ps1')
        for forbidden in ('Import-PfxCertificate', 'New-SelfSignedCertificate', 'ConvertTo-SecureString'):
            self.assertNotIn(forbidden, source)
        for required in ('CurrentUser\\My', 'HasPrivateKey', 'TimeStamperCertificate', 'Get-AuthenticodeSignature', '2.5.29.37'):
            self.assertIn(required, source)

    def test_ci_executes_pester_and_uploads_results(self):
        source = text('.github/workflows/validate.yml')
        self.assertIn('Run-Pester.ps1', source)
        self.assertIn('5.7.1', source)
        self.assertRegex(source, r'actions/upload-artifact@[a-f0-9]{40}')

    def test_final_docs_and_license_exist(self):
        for path in ('MANUAL.md', 'BUILD.md', 'CHANGELOG.md', 'LICENSE', 'docs/ROADMAP-v4.0.0.md'):
            self.assertGreater(len(text(path)), 100)
        self.assertIn('MIT License', text('LICENSE'))
        self.assertIn('Permission is hereby granted', text('LICENSE'))
        self.assertIn('no implementado', text('docs/ROADMAP-v4.0.0.md'))

    def test_msi_prevents_mixing_script_install(self):
        root = ET.fromstring(text('packaging/Suite.wxs'))
        ns = {'w': 'http://schemas.microsoft.com/wix/2006/wi'}
        conditions = [e.text for e in root.findall('w:Product/w:Condition', ns)]
        self.assertIn('Installed OR NOT ATSSCRIPTINSTALL', conditions)


if __name__ == '__main__':
    unittest.main()
