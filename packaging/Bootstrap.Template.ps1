#requires -Version 5.1
<#
.SYNOPSIS
ATS v4 - Un unico fichero que materializa el proyecto completo sin descargas.
.DESCRIPTION
-ValidateOnly verifica el contenido sin escribir. -WhatIf muestra el destino sin crearlo.
No instala el programa, no eleva privilegios ni ejecuta acciones administrativas.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Destination = (Join-Path $PSScriptRoot 'AdvancedToolSuite-v4.0.0'),
    [switch]$Launch,
    [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$archiveBase64 = @'
__ARCHIVE_BASE64__
'@
$indexBase64 = @'
__INDEX_BASE64__
'@
$expectedArchiveHash = '__ARCHIVE_SHA256__'
Add-Type -AssemblyName System.IO.Compression
$bytes = [Convert]::FromBase64String($archiveBase64)
$sha = [Security.Cryptography.SHA256]::Create()
try { $actualHash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','') } finally { $sha.Dispose() }
if ($actualHash -cne $expectedArchiveHash) { throw 'El paquete embebido no coincide con su SHA256. No se extraera.' }
$index = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($indexBase64)) | ConvertFrom-Json
if ($index.version -ne '4.0.0' -or @($index.files).Count -lt 10) { throw 'Indice del proyecto no valido.' }
$approved = @{}
$total = [long]0
foreach ($record in @($index.files)) {
    $path = [string]$record.path
    if (-not $path -or $path.Length -gt 180 -or $path -match '(^/|\\|:|\x00)' -or $path -match '(^|/)\.\.?(/|$)') { throw "Ruta no permitida en el indice: $path" }
    foreach ($segment in $path.Split('/')) {
        if (-not $segment -or $segment.EndsWith('.') -or $segment.EndsWith(' ') -or $segment -match '[<>"|?*\x00-\x1f]' -or $segment -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)') { throw 'Nombre incompatible con Windows.' }
    }
    if ($approved.ContainsKey($path) -or $record.sha256 -notmatch '^[A-F0-9]{64}$' -or $record.size -lt 0 -or $record.size -gt 4194304) { throw 'Indice duplicado o tamano/hash no permitido.' }
    $total += $record.size
    $approved[$path] = $record
}
if ($total -gt 16777216 -or $approved.Count -gt 512) { throw 'El proyecto excede los limites de extraccion.' }
$memory = [IO.MemoryStream]::new($bytes,$false)
$archive = [IO.Compression.ZipArchive]::new($memory,[IO.Compression.ZipArchiveMode]::Read,$false)
$stage = $null
try {
    if ($archive.Entries.Count -ne $approved.Count) { throw 'El ZIP no coincide con el numero de archivos del indice.' }
    $seen = @{}
    # Verificar TODOS los archivos en memoria antes de crear directorios.
    foreach ($entry in $archive.Entries) {
        if (-not $approved.ContainsKey($entry.FullName) -or $seen.ContainsKey($entry.FullName)) { throw 'Entrada no permitida o duplicada en el ZIP.' }
        $record = $approved[$entry.FullName]
        if ($entry.Length -ne $record.size -or (($entry.ExternalAttributes -shr 16) -band 61440) -eq 40960) { throw 'Tamano inesperado o enlace simbolico en el ZIP.' }
        $stream = $entry.Open(); $sha = [Security.Cryptography.SHA256]::Create()
        try { $hash = ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','') } finally { $sha.Dispose(); $stream.Dispose() }
        if ($hash -cne $record.sha256) { throw "Integridad incorrecta: $($entry.FullName)" }
        $seen[$entry.FullName] = $true
    }
    if ($ValidateOnly) {
        Write-Output "Paquete ATS $($index.version) integro: $($approved.Count) archivos / $total bytes. No se escribio ni ejecuto nada."
        return
    }
    if ($env:OS -ne 'Windows_NT') { throw 'Ejecuta la extraccion con Windows PowerShell 5.1 en Windows 10/11.' }
    $target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)
    $target = [IO.Path]::GetFullPath($target).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $target) { throw 'El destino ya existe. Elige una carpeta nueva: no se sobrescriben archivos.' }
    $parent = [IO.Path]::GetDirectoryName($target)
    if (-not $parent -or -not (Test-Path -LiteralPath $parent -PathType Container)) { throw 'La carpeta padre del destino debe existir.' }
    $check = $parent
    while ($check) {
        if (((Get-Item -LiteralPath $check -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'No se admiten enlaces/junctions en la cadena del destino.' }
        $check = [IO.Path]::GetDirectoryName($check)
    }
    if (-not $PSCmdlet.ShouldProcess($target,"Crear proyecto completo ATS $($index.version) con $($approved.Count) archivos verificados")) { return }
    # Staging exclusivo en el mismo volumen: el destino final aparece solo tras extraer todo.
    $stage = Join-Path $parent ('ATS-extract-' + [guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($stage)
    $prefix = $stage + [IO.Path]::DirectorySeparatorChar
    foreach ($entry in $archive.Entries) {
        $relative = $entry.FullName.Replace('/',[IO.Path]::DirectorySeparatorChar)
        $output = [IO.Path]::GetFullPath((Join-Path $stage $relative))
        if (-not $output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'Ruta fuera del directorio de extraccion.' }
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($output))
        $input = $entry.Open()
        $file = [IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try { $input.CopyTo($file) } finally { $file.Dispose(); $input.Dispose() }
        if ((Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash -cne $approved[$entry.FullName].sha256) { throw 'Fallo de verificacion despues de escribir.' }
    }
    # Directory.Move falla si alguien crea el destino mientras se extrae. No fusiona ni reemplaza.
    [IO.Directory]::Move($stage,$target)
    $stage = $null
    Write-Output "Proyecto completo creado en: $target"
    Write-Output 'Abre LEEME-PRIMERO.md o Tool\Iniciar.cmd. No se han instalado tareas, entradas de registro ni plugins.'
    if ($Launch -and $PSCmdlet.ShouldProcess((Join-Path $target 'Tool\AdvancedToolSuite.ps1'),'Abrir el panel WPF')) {
        Start-Process "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList ('-NoProfile -STA -File "{0}"' -f (Join-Path $target 'Tool\AdvancedToolSuite.ps1'))
    }
} finally {
    $archive.Dispose(); $memory.Dispose()
    # Solo retira la carpeta temporal creada por esta ejecucion; nunca borra el destino final.
    if ($null -ne $stage -and (Test-Path -LiteralPath $stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
