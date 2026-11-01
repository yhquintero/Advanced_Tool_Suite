#requires -Version 5.1
# Prueba real del escritor HKCU en una clave temporal, sin instalar ATS ni requerir Windows Client.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'packaging\Deployment.Common.ps1')
$path = 'HKCU:\Software\ATS-Registry-Test-' + [guid]::NewGuid().ToString('N')
try {
    $createdKey = New-Item -Path $path
    $createdKey.Dispose()
    Set-ATSUserRegistryValue -Path $path -Name 'DisplayName' -Value 'ATS test' -Kind String
    Set-ATSUserRegistryValue -Path $path -Name 'NoModify' -Value 1 -Kind DWord
    Set-ATSUserRegistryValue -Path $path -Name 'NoRepair' -Value 1 -Kind DWord
    Set-ATSUserRegistryValue -Path $path -Name '' -Value '' -Kind String
    Set-ATSUserRegistryValue -Path $path -Name 'RawPath' -Value '%TEMP%\ATS' -Kind ExpandString
    Set-ATSUserRegistryValue -Path $path -Name 'Multiple' -Value ([string[]]@('uno','dos')) -Kind MultiString
    Set-ATSUserRegistryValue -Path $path -Name 'Binary' -Value ([byte[]]@(1,2,3)) -Kind Binary
    Set-ATSUserRegistryValue -Path $path -Name 'EmptyBinary' -Value ([byte[]]@()) -Kind Binary
    $read = Get-Item -LiteralPath $path
    try {
        if ($read.GetValue('DisplayName') -ne 'ATS test') { throw 'String no guardado.' }
        foreach ($name in @('NoModify','NoRepair')) {
            if ($read.GetValue($name) -ne 1 -or $read.GetValueKind($name) -ne 'DWord') { throw 'DWORD incorrecto.' }
        }
        $snapshot = @{}
        foreach ($name in $read.GetValueNames()) {
            $snapshot[$name] = @{Value=$read.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames); Kind=$read.GetValueKind($name)}
        }
    } finally { $read.Dispose() }
    # Restaurar con el mismo escritor que utiliza el catch del instalador.
    Remove-Item -LiteralPath $path -Recurse
    $createdKey = New-Item -Path $path
    $createdKey.Dispose()
    foreach ($name in $snapshot.Keys) {
        Set-ATSUserRegistryValue -Path $path -Name $name -Value $snapshot[$name].Value -Kind $snapshot[$name].Kind
    }
    $read = Get-Item -LiteralPath $path
    try {
        foreach ($name in $snapshot.Keys) {
            $actual = $read.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            if ($read.GetValueKind($name) -ne $snapshot[$name].Kind -or (@($actual) -join '|') -cne (@($snapshot[$name].Value) -join '|')) {
                throw "Restauracion incorrecta: $name"
            }
        }
    } finally { $read.Dispose() }
    # No tocar HKLM y no crear una clave inexistente silenciosamente.
    $rejected = $false
    try { Set-ATSUserRegistryValue -Path 'HKLM:\Software\ATS-DO-NOT-CREATE' -Name 'x' -Value 1 -Kind DWord } catch { $rejected = $true }
    if (-not $rejected) { throw 'Se acepto un hive ajeno a HKCU.' }
    $rejected = $false
    try { Set-ATSUserRegistryValue -Path ($path + '\Missing') -Name 'x' -Value 1 -Kind DWord } catch { $rejected = $true }
    if (-not $rejected -or (Test-Path -LiteralPath ($path + '\Missing'))) { throw 'Se creo una clave implicitamente.' }
    Write-Output 'Registro: escritura tipada, restauracion y cierre de claves comprobados en HKCU temporal.'
} finally {
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
}
