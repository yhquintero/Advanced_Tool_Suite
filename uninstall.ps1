#requires -Version 5.1
<# .SYNOPSIS
Retira solo archivos gestionados de la instalacion por usuario; conserva datos e informes.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param()
$ErrorActionPreference = 'Stop'
$common = Join-Path $PSScriptRoot 'Deployment.Common.ps1'
if (-not (Test-Path $common)) { $common = Join-Path $PSScriptRoot 'packaging\Deployment.Common.ps1' }
. $common
$config = Get-ATSDeployment
Assert-ATSPlainDirectory $config.Root
if (-not (Test-Path -LiteralPath $config.Root)) { Write-Output 'No hay una instalacion por usuario en la ruta gestionada.'; return }
$receipt = Read-ATSReceipt $config.Root
$launch = Get-ATSLaunch $config.Root $receipt.EntryPoint
if (-not $PSCmdlet.ShouldProcess($config.Root,'Desinstalar Advanced Tool Suite conservando preferencias, logs, tareas e informes')) { return }
# No elimina entradas de otro producto o de una copia portable distinta.
$context = 'HKCU:\Software\Classes\Directory\Background\shell\AdvancedToolSuite'
if (Test-Path "$context\command") {
    $currentCommand = (Get-Item "$context\command").GetValue('')
    $expected = ('"' + $launch.Target + '"' + $(if ($launch.Arguments) { ' ' + $launch.Arguments } else { '' }))
    if ($currentCommand -eq $expected) { Remove-Item $context -Recurse }
    else { Write-Warning 'Se conserva una entrada contextual que apunta a otra ubicacion.' }
}
if (Test-Path -LiteralPath $config.Shortcut) {
    if (Test-ATSShortcut $config.Shortcut $launch) { Remove-Item -LiteralPath $config.Shortcut }
    else { Write-Warning 'Se conserva el acceso directo porque fue modificado o apunta a otra ubicacion.' }
}
try {
    # La lista ya fue validada: no acepta rutas, comodines ni nombres ajenos.
    foreach ($file in @($receipt.Files)) {
        $path = Join-Path $config.Root $file.Name
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
    Remove-Item -LiteralPath (Join-Path $config.Root $config.Receipt)
    if (@(Get-ChildItem -LiteralPath $config.Root -Force).Count -eq 0) { Remove-Item -LiteralPath $config.Root }
    else { Write-Warning 'Se conservan archivos ajenos presentes en la carpeta de instalacion.' }
    if (Test-Path $config.UninstallKey) {
        $key = Get-Item $config.UninstallKey
        if ($key.GetValue('ATSProductId') -eq $config.ProductId -and $key.GetValue('InstallLocation') -eq $config.Root) { Remove-Item $config.UninstallKey -Recurse }
        else { Write-Warning 'La entrada de desinstalacion no coincide; se conserva para revision manual.' }
    }
    Write-ATSDeploymentLog "UNINSTALL_OK / $($receipt.Version)"
    Write-Output 'Desinstalado. Se conservan preferencias, auditoria, informes y tareas ATS-Informe-*.'
} catch { Write-ATSDeploymentLog ('UNINSTALL_ERROR / ' + $_.Exception.Message); throw }
