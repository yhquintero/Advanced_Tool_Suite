#requires -Version 5.1
<# .SYNOPSIS
Muestra el About propuesto. Solo -Apply intenta modificar metadatos mediante gh, respetando WhatIf.
#>
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Apply)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$metadata = Get-Content (Join-Path $root '.github\repository.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($metadata.description.Length -lt 1 -or $metadata.description.Length -gt 350) { throw 'About debe tener entre 1 y 350 caracteres.' }
$uri = [uri]$metadata.homepage
if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'github.com') { throw 'No se publicara una web no verificada. Revisa el homepage propuesto.' }
foreach ($topic in $metadata.topics) {
    if ($topic -notmatch '^[a-z0-9][a-z0-9-]{0,49}$') { throw 'Topic no valido.' }
}
Write-Output ('About ({0}/350): {1}' -f $metadata.description.Length,$metadata.description)
Write-Output ('Website: ' + $metadata.homepage)
Write-Output ('Topics: ' + ($metadata.topics -join ', '))
if (-not $Apply) { Write-Output 'Solo vista previa. Usa -Apply con una conexion autorizada por el propietario.'; return }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'Instala GitHub CLI e inicia una conexion autorizada; no compartas credenciales en el proyecto.' }
if ($PSCmdlet.ShouldProcess('yhquintero/Advanced_Tool_Suite','Actualizar descripcion, website y agregar topics')) {
    $arguments = @('repo','edit','yhquintero/Advanced_Tool_Suite','--description',$metadata.description,'--homepage',$metadata.homepage)
    foreach ($topic in $metadata.topics) { $arguments += @('--add-topic',$topic) }
    & gh @arguments
    if ($LASTEXITCODE -ne 0) { throw 'GitHub rechazo la actualizacion. Revisa permisos de la conexion; no se confirma ningun cambio de About.' }
    Write-Output 'Solicitud aceptada. Verifica el About visible con gh repo view.'
}
