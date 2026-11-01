#requires -Version 5.1
# Pruebas sin Pester: no abre aplicaciones ni modifica el registro, tareas o firewall.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$path = Join-Path (Split-Path $PSScriptRoot -Parent) 'Tool\AdvancedToolSuite.ps1'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw 'El archivo no pasa el analisis sintactico.' }
foreach ($name in @('Test-ReadOnlyTool','Get-RegistrySpec','Write-RotatingLog')) {
    $function = $ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] },$true) | Where-Object Name -eq $name | Select-Object -First 1
    if ($null -eq $function) { throw "No existe la funcion $name" }
    # Solo funciones estaticas del repositorio, nunca contenido de logs o preferencias.
    . ([ScriptBlock]::Create($function.Extent.Text))
}
foreach ($id in @(1,11,14,19,27,28,29,30)) { if (-not (Test-ReadOnlyTool $id)) { throw "Diagnostico bloqueado: $id" } }
foreach ($id in @(6,8,10,12,17,18,22,23,25,26,32,33,34,40,41)) { if (Test-ReadOnlyTool $id) { throw "Accion peligrosa permitida: $id" } }
foreach ($id in @(10,17,18,25,26)) {
    $spec = Get-RegistrySpec $id
    if ($spec.Path -notlike 'HKCU:\*') { throw 'Ruta de registro fuera de la lista permitida.' }
}
$rejected = $false
try { Get-RegistrySpec 999 | Out-Null } catch { $rejected = $true }
if (-not $rejected) { throw 'Se admitio un ID de registro no permitido.' }
$temp = Join-Path ([IO.Path]::GetTempPath()) ('ATS-Contract-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item $temp -ItemType Directory | Out-Null
    $log = Join-Path $temp 'test.log'
    [IO.File]::WriteAllText($log, ('x' * 5242881))
    Write-RotatingLog $log 'evento nuevo'
    if (-not (Test-Path "$log.1")) { throw 'No se roto el registro.' }
    if ((Get-Content $log -Raw) -notmatch 'evento nuevo') { throw 'No se escribio el evento nuevo.' }
    for ($n=0; $n -lt 7; $n++) {
        [IO.File]::WriteAllText($log, ('x' * 5242881))
        Write-RotatingLog $log 'rotacion'
    }
    if (Test-Path "$log.6") { throw 'No se respeto el limite de cinco copias.' }
} finally { if (Test-Path $temp) { Remove-Item $temp -Recurse -Force } }
Write-Output 'Contratos correctos: solo lectura, registro por lista blanca y rotacion de logs.'
