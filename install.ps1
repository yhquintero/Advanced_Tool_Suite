#requires -Version 5.1
<# .SYNOPSIS
Instalacion por usuario desde fuentes (prepara Portable) o una distribucion Portable/Exe.
#>
[CmdletBinding(SupportsShouldProcess)]
param([string]$SourceDirectory = $PSScriptRoot, [switch]$RequireSignature)
$ErrorActionPreference = 'Stop'
$common = Join-Path $PSScriptRoot 'Deployment.Common.ps1'
if (-not (Test-Path $common)) { $common = Join-Path $PSScriptRoot 'packaging\Deployment.Common.ps1' }
. $common
$config = Get-ATSDeployment
$source = (Resolve-Path -LiteralPath $SourceDirectory).ProviderPath
# Solo el arbol de fuentes de este instalador puede preparar un paquete automaticamente.
# Un paquete incompleto/alterado o un SourceDirectory ajeno sigue fallando cerrado.
$builder = Join-Path $source 'packaging\Build-Release.ps1'
$isSourceTree = ($source -eq $PSScriptRoot) -and
    (-not (Test-Path -LiteralPath (Join-Path $source 'SHA256.json'))) -and
    (Test-Path -LiteralPath $builder -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $source 'Tool\AdvancedToolSuite.ps1') -PathType Leaf)
if ($isSourceTree) {
    if ($RequireSignature) {
        throw 'Las fuentes no son un paquete firmado. Construye y firma una distribucion; usa -SourceDirectory con ese paquete y -RequireSignature.'
    }
    $version = (Get-Content -LiteralPath (Join-Path $source 'VERSION.json') -Raw -Encoding UTF8 | ConvertFrom-Json).version
    if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Version de fuentes no valida.' }
    $prepared = Join-Path $source ("artifacts\$version\Portable-install-" + [guid]::NewGuid().ToString('N'))
    if (-not $PSCmdlet.ShouldProcess($prepared, 'Preparar un paquete Portable SIN FIRMA desde las fuentes locales antes de instalar')) { return }
    Write-Warning 'Estas instalando fuentes locales. Se generara un paquete Portable sin firma; los hashes no autentican al editor.'
    # Usar el motor soportado aunque el usuario invoque install.ps1 desde PowerShell 7.
    $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    & $windowsPowerShell -NoProfile -File $builder -Format Portable -OutputDirectory $prepared
    if ($LASTEXITCODE -ne 0) { throw "No se pudo preparar el paquete Portable (codigo $LASTEXITCODE). No se ha instalado nada. Revisa la salida anterior: $prepared" }
    $source = $prepared
}
$package = Assert-ATSPackage $source -RequireSignature:$RequireSignature
Assert-ATSPlainDirectory $config.Root
$previousReceipt = $null
if (Test-Path -LiteralPath $config.Root) {
    $previousReceipt = Read-ATSReceipt $config.Root
    if ([version]$previousReceipt.Version -gt [version]$package.Version) { throw 'Se rechaza instalar una version anterior.' }
    $known = @($previousReceipt.Files.Name) + $config.Receipt
    if (@(Get-ChildItem -LiteralPath $config.Root -Force | Where-Object Name -NotIn $known).Count) { throw 'Hay archivos no gestionados en el destino. Conservalos fuera antes de actualizar.' }
}
if (Test-Path $config.UninstallKey) {
    $ownerKey = Get-Item $config.UninstallKey
    try {
        if ($ownerKey.GetValue('ATSProductId') -ne $config.ProductId) { throw 'La entrada de desinstalacion pertenece a otro producto.' }
    } finally { $ownerKey.Dispose() }
}
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
    try {
        foreach ($name in $key.GetValueNames()) { $oldRegistry[$name] = @{Value=$key.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames); Kind=$key.GetValueKind($name)} }
    } finally { $key.Dispose() }
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
    if (-not $registryExisted) {
        $createdKey = New-Item $config.UninstallKey -Force
        $createdKey.Dispose()
    }
    $uninstall = '"{0}" -NoProfile -File "{1}"' -f "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe",(Join-Path $config.Root 'uninstall.ps1')
    foreach ($pair in @{
        DisplayName='Advanced Tool Suite'; DisplayVersion=$package.Version; Publisher='Advanced Tool Suite contributors'
        InstallLocation=$config.Root; DisplayIcon=(Join-Path $config.Root 'Suite.ico'); UninstallString=$uninstall
        ATSProductId=$config.ProductId
    }.GetEnumerator()) { Set-ATSUserRegistryValue -Path $config.UninstallKey -Name $pair.Key -Value $pair.Value -Kind String }
    Set-ATSUserRegistryValue -Path $config.UninstallKey -Name 'NoModify' -Value 1 -Kind DWord
    Set-ATSUserRegistryValue -Path $config.UninstallKey -Name 'NoRepair' -Value 1 -Kind DWord
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
        $createdKey = New-Item $config.UninstallKey -Force
        $createdKey.Dispose()
        foreach ($name in $oldRegistry.Keys) { Set-ATSUserRegistryValue -Path $config.UninstallKey -Name $name -Value $oldRegistry[$name].Value -Kind $oldRegistry[$name].Kind }
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
