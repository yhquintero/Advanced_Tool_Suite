#requires -Version 5.1
# Contratos v4: solo valida datos; no muestra UI ni ejecuta diagnosticos.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'Plugins\Plugin.Core.ps1')
function New-TestPlugin {
    return @{schemaVersion=1; id='ats-test'; name='Prueba'; version='1.0.0'; description='Diagnostico de prueba'; toolId=14}
}
function Assert-Rejected([string]$Json) {
    $rejected = $false
    try { ConvertFrom-ATSPlugin $Json | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Se acepto un manifiesto que debia rechazarse.' }
}
foreach ($file in Get-ChildItem (Join-Path $root 'Plugins\Examples') -Filter '*.json') {
    $plugin = ConvertFrom-ATSPlugin (Get-Content $file.FullName -Raw)
    if ($plugin.toolId -notin @(1,14,19,27,28,30)) { throw 'Ejemplo fuera de la lista permitida.' }
}
$sample = New-TestPlugin; $sample.command = 'Get-Process'; Assert-Rejected ($sample | ConvertTo-Json)
$sample = New-TestPlugin; $sample.toolId = 34; Assert-Rejected ($sample | ConvertTo-Json)
$sample = New-TestPlugin; $sample.toolId = '14'; Assert-Rejected ($sample | ConvertTo-Json)
$sample = New-TestPlugin; $sample.id = '../fuera'; Assert-Rejected ($sample | ConvertTo-Json)
$sample = New-TestPlugin; $sample.schemaVersion = 2; Assert-Rejected ($sample | ConvertTo-Json)
$sample = New-TestPlugin; $sample.name = ' '; Assert-Rejected ($sample | ConvertTo-Json)
$sample = New-TestPlugin; $sample.description = "primera`nsegunda"; Assert-Rejected ($sample | ConvertTo-Json)
Assert-Rejected ('x' * 16385)
Assert-Rejected '[]'
Assert-Rejected 'null'
Assert-Rejected '{'
# La aprobacion es por ID y SHA256; cambiar el archivo lo deja inactivo.
$temp = Join-Path ([IO.Path]::GetTempPath()) ('ATS-PluginTest-' + [guid]::NewGuid().ToString('N'))
try {
    $script:DataPath = $temp
    $script:Settings = @{EnabledPlugins=@()}
    $script:Errors = @()
    function Write-Activity([string]$Message,[string]$Status,[int]$ActionId) { $script:Errors += $Message }
    $folder = Join-Path $temp 'Plugins'
    New-Item $folder -ItemType Directory -Force | Out-Null
    $path = Join-Path $folder 'ats-test.json'
    New-TestPlugin | ConvertTo-Json | Set-Content $path -Encoding UTF8
    $records = @(Get-ATSPlugins)
    if ($records.Count -ne 1 -or $records[0].Enabled) { throw 'Importacion no activa por defecto incumplida.' }
    $script:Settings.EnabledPlugins = @('ats-test:' + $records[0].Hash)
    if (-not @(Get-ATSPlugins)[0].Enabled) { throw 'No se reconocio la aprobacion exacta.' }
    $sample = New-TestPlugin; $sample.toolId=27; $sample | ConvertTo-Json | Set-Content $path -Encoding UTF8
    if (@(Get-ATSPlugins)[0].Enabled) { throw 'Una modificacion no invalido la aprobacion.' }
    $sample = New-TestPlugin; $sample.id='id-distinto'; $sample | ConvertTo-Json | Set-Content $path -Encoding UTF8
    if (@(Get-ATSPlugins).Count -ne 0) { throw 'Se acepto ID distinto al archivo.' }
} finally { if (Test-Path $temp) { Remove-Item $temp -Recurse -Force } }
Write-Output 'Contratos de plugins correctos: datos, limites, inactivo por defecto y aprobacion por SHA256.'
