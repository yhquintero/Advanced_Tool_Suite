#requires -Version 5.1
<# .SYNOPSIS
Instalacion por usuario desde una distribucion Portable/Exe generada por Build-Release.
#>
[CmdletBinding(SupportsShouldProcess)]
param([string]$SourceDirectory = $PSScriptRoot, [switch]$RequireSignature)
$ErrorActionPreference = 'Stop'
$common = Join-Path $PSScriptRoot 'Deployment.Common.ps1'
if (-not (Test-Path $common)) { $common = Join-Path $PSScriptRoot 'packaging\Deployment.Common.ps1' }
. $common
$config = Get-ATSDeployment
$source = (Resolve-Path -LiteralPath $SourceDirectory).ProviderPath
$package = Assert-ATSPackage $source -RequireSignature:$RequireSignature
Assert-ATSPlainDirectory $config.Root
$previousReceipt = $null
if (Test-Path -LiteralPath $config.Root) {
    $previousReceipt = Read-ATSReceipt $config.Root
    if ([version]$previousReceipt.Version -gt [version]$package.Version) { throw 'Se rechaza instalar una version anterior.' }
    $known = @($previousReceipt.Files.Name) + $config.Receipt
    if (@(Get-ChildItem -LiteralPath $config.Root -Force | Where-Object Name -NotIn $known).Count) { throw 'Hay archivos no gestionados en el destino. Conservalos fuera antes de actualizar.' }
}
if ((Test-Path $config.UninstallKey) -and ((Get-Item $config.UninstallKey).GetValue('ATSProductId') -ne $config.ProductId)) { throw 'La entrada de desinstalacion pertenece a otro producto.' }
if ((Test-Path -LiteralPath $config.Shortcut) -and $null -eq $previousReceipt) { throw 'Ya existe un acceso directo sin una instalacion ATS reconocida.' }
Assert-ATSPlainDirectory (Split-Path $config.Shortcut -Parent)
if ($null -ne $previousReceipt -and (Test-Path -LiteralPath $config.Shortcut)) {
    if (-not (Test-ATSShortcut $config.Shortcut (Get-ATSLaunch $config.Root $previousReceipt.EntryPoint))) { throw 'El acceso directo fue modificado. Revisalo antes de actualizar.' }
}
if (-not $PSCmdlet.ShouldProcess($config.Root,"Instalar/actualizar Advanced Tool Suite $($package.Version) para este usuario")) { return }
$parent = Split-Path $config.Root -Parent
New-Item $parent -ItemType Directory -Force | Out-Null
$stage = Join-Path $parent ('ATS-stage-' + [guid]::NewGuid().ToString('N'))
$backup = Join-Path $parent ('ATS-backup-' + [guid]::NewGuid().ToString('N'))
$shortcutBackup = $null; $oldRegistry = @{}; $registryExisted = Test-Path $config.UninstallKey
$swapped = $false; $newInstalled = $false
if ($registryExisted) {
    $key = Get-Item $config.UninstallKey
    foreach ($name in $key.GetValueNames()) { $oldRegistry[$name] = @{Value=$key.GetValue($name); Kind=$key.GetValueKind($name)} }
}
try {
    New-Item $stage -ItemType Directory | Out-Null
    $records = @()
    foreach ($name in $package.Files) {
        Copy-Item -LiteralPath (Join-Path $source $name) -Destination (Join-Path $stage $name)
        $records += @{Name=$name; Hash=(Get-FileHash (Join-Path $stage $name) -Algorithm SHA256).Hash}
    }
    [void](Assert-ATSPackage $stage -RequireSignature:$RequireSignature)
    @{ProductId=$config.ProductId; Version=$package.Version; EntryPoint=$package.EntryPoint; InstalledUtc=[DateTime]::UtcNow.ToString('o'); Files=$records} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $stage $config.Receipt) -Encoding UTF8
    if (Test-Path -LiteralPath $config.Shortcut) { $shortcutBackup = [IO.File]::ReadAllBytes($config.Shortcut) }
    if (Test-Path -LiteralPath $config.Root) { Move-Item -LiteralPath $config.Root -Destination $backup; $swapped = $true }
    Move-Item -LiteralPath $stage -Destination $config.Root; $newInstalled = $true
    if (-not $registryExisted) { New-Item $config.UninstallKey -Force | Out-Null }
    $key = Get-Item $config.UninstallKey
    $uninstall = '"{0}" -NoProfile -File "{1}"' -f "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe",(Join-Path $config.Root 'uninstall.ps1')
    foreach ($pair in @{
        DisplayName='Advanced Tool Suite'; DisplayVersion=$package.Version; Publisher='Advanced Tool Suite contributors'
        InstallLocation=$config.Root; DisplayIcon=(Join-Path $config.Root 'Suite.ico'); UninstallString=$uninstall
        ATSProductId=$config.ProductId
    }.GetEnumerator()) { $key.SetValue($pair.Key,$pair.Value,[Microsoft.Win32.RegistryValueKind]::String) }
    $key.SetValue('NoModify',1,[Microsoft.Win32.RegistryValueKind]::DWord)
    $key.SetValue('NoRepair',1,[Microsoft.Win32.RegistryValueKind]::DWord)
    $launch = Get-ATSLaunch $config.Root $package.EntryPoint
    $shell = New-Object -ComObject WScript.Shell
    try {
        $link = $shell.CreateShortcut($config.Shortcut)
        try {
            $link.TargetPath = $launch.Target; $link.Arguments = $launch.Arguments
            $link.WorkingDirectory = $config.Root; $link.IconLocation = (Join-Path $config.Root 'Suite.ico')
            $link.Description = 'Advanced Tool Suite - Centro de control'; $link.Save()
        } finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($link) }
    } finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) }
} catch {
    $failure = $_
    # Rollback de lo gestionado; se conserva el backup si la recuperacion falla.
    if ($newInstalled) { Remove-Item -LiteralPath $config.Root -Recurse -Force }
    if ($swapped) { Move-Item -LiteralPath $backup -Destination $config.Root }
    if (Test-Path $config.UninstallKey) { Remove-Item $config.UninstallKey -Recurse }
    if ($registryExisted) {
        New-Item $config.UninstallKey -Force | Out-Null; $key = Get-Item $config.UninstallKey
        foreach ($name in $oldRegistry.Keys) { $key.SetValue($name,$oldRegistry[$name].Value,$oldRegistry[$name].Kind) }
    }
    if ($null -ne $shortcutBackup) { [IO.File]::WriteAllBytes($config.Shortcut,$shortcutBackup) }
    elseif (Test-Path -LiteralPath $config.Shortcut) { Remove-Item -LiteralPath $config.Shortcut }
    Write-ATSDeploymentLog ('INSTALL_ERROR / ' + $failure.Exception.Message)
    throw $failure
} finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
if ($swapped -and (Test-Path -LiteralPath $backup)) { Remove-Item -LiteralPath $backup -Recurse -Force }
Write-ATSDeploymentLog "INSTALL_OK / $($package.Version) / $($config.Root)"
Write-Output "Instalado en $($config.Root). Acceso directo en Inicio y entrada en Aplicaciones instaladas."
