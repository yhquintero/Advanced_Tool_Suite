#requires -Version 5.1
# Regresion Windows: prepara/valida paquetes y simula, sin instalar ni cambiar HKCU/Inicio.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$isClient = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType -eq 'Client'
$artifacts = Join-Path $root 'artifacts'
$before = @(if (Test-Path -LiteralPath $artifacts) { Get-ChildItem -LiteralPath $artifacts -Recurse -Force | Select-Object -ExpandProperty FullName }) -join "`n"
if ($isClient) { & (Join-Path $root 'install.ps1') -WhatIf }
else { Write-Warning 'Windows Server: simulaciones de install.ps1 omitidas; el instalador exige Windows 10/11 Client. Se probaran construccion, hashes y alteraciones.' }
$after = @(if (Test-Path -LiteralPath $artifacts) { Get-ChildItem -LiteralPath $artifacts -Recurse -Force | Select-Object -ExpandProperty FullName }) -join "`n"
if ($before -ne $after) { throw 'WhatIf desde fuentes escribio archivos de construccion.' }
$target = Join-Path $env:TEMP ('ATS-install-source-test-' + [guid]::NewGuid().ToString('N'))
try {
    & (Join-Path $root 'packaging\Build-Release.ps1') -Format Portable -OutputDirectory $target
    . (Join-Path $root 'packaging\Deployment.Common.ps1')
    $package = Assert-ATSPackage $target
    if ($package.EntryPoint -ne 'AdvancedToolSuite.ps1') { throw 'No se genero el portable esperado.' }
    if ($isClient) { & (Join-Path $root 'install.ps1') -SourceDirectory $target -WhatIf }
    # La nueva preparacion no debe permitir instalar un paquete alterado.
    Add-Content -LiteralPath (Join-Path $target 'AdvancedToolSuite.ps1') -Value '# alterado' -Encoding UTF8
    $rejected = $false
    try { Assert-ATSPackage $target | Out-Null } catch {
        if ($_.Exception.Message -notlike 'Hash no coincide:*') { throw }
        $rejected = $true
    }
    if (-not $rejected) { throw 'Se acepto un paquete alterado.' }
    Write-Output 'Paquete portable y rechazo de alteraciones correctos; simulaciones de instalacion solo en Windows Client.'
} finally {
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
}
