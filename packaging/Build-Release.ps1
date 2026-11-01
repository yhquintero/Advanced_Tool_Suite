#requires -Version 5.1
<#
.SYNOPSIS
Genera una distribucion de Windows (portable, EXE o MSI).
.DESCRIPTION
No descarga herramientas ni certificados. Portable no necesita dependencias de compilacion.
EXE requiere ps2exe 1.0.17 instalado previamente. MSI requiere ademas WiX Toolset 3.x.
#>
[CmdletBinding()]
param(
    [ValidateSet('Portable','Exe','Msi')][string]$Format = 'Portable',
    [string]$OutputDirectory,
    [version]$Ps2ExeVersion = '1.0.17',
    [ValidatePattern('^[a-fA-F0-9]{40}$')][string]$CertificateThumbprint,
    [uri]$TimestampServer
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'La compilacion de distribuciones debe realizarse en Windows.' }
$root = Split-Path $PSScriptRoot -Parent
$version = (Get-Content (Join-Path $root 'VERSION.json') -Raw | ConvertFrom-Json).version
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Version de paquete no valida.' }
$out = if ($OutputDirectory) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory) } else { Join-Path $root "artifacts\$version\$Format" }
if ((Test-Path $out) -and @(Get-ChildItem $out -Force).Count -gt 0) { throw "La salida $out no esta vacia. Archivala o retirala antes de reconstruir para evitar archivos obsoletos." }
if ($CertificateThumbprint -and $null -eq $TimestampServer) { throw 'La firma requiere -TimestampServer HTTPS.' }
if ($null -ne $TimestampServer -and -not $CertificateThumbprint) { throw 'El sello de tiempo requiere -CertificateThumbprint.' }
New-Item $out -ItemType Directory -Force | Out-Null
$source = Join-Path $root 'Tool\AdvancedToolSuite.ps1'
& (Join-Path $root 'tests\Validar-PowerShell.ps1')
if ($Format -eq 'Portable') {
    # Los SVG y el XAML ya estan embebidos. Este archivo es toda la aplicacion.
    Copy-Item $source (Join-Path $out 'AdvancedToolSuite.ps1') -Force
} else {
    $module = Get-Module -ListAvailable ps2exe | Where-Object Version -eq $Ps2ExeVersion | Select-Object -First 1
    if ($null -eq $module) { throw "Instala y revisa ps2exe $Ps2ExeVersion antes de compilar. No se descargan dependencias automaticamente." }
    Import-Module $module.Path -Force
    $compile = @{
        inputFile=$source; outputFile=(Join-Path $out 'AdvancedToolSuite.exe')
        STA=$true; noConsole=$true; x64=$true; iconFile=(Join-Path $root 'Assets\Suite.ico')
        title='Advanced Tool Suite'; description='Centro de control local para Windows'
        product='Advanced Tool Suite'; version="$version.0"; noOutput=$true
    }
    if (-not (Get-Command 'mt.exe' -ErrorAction SilentlyContinue)) { throw 'Falta mt.exe de Windows SDK en PATH para incrustar y verificar manifest.xml.' }
    Invoke-ps2exe @compile
    if (-not (Test-Path (Join-Path $out 'AdvancedToolSuite.exe'))) { throw 'ps2exe no genero el ejecutable.' }
    # El manifiesto se incrusta ANTES de firmar; mutar el EXE despues invalidaria la firma.
    $exe = Join-Path $out 'AdvancedToolSuite.exe'
    & mt.exe -nologo -manifest (Join-Path $PSScriptRoot 'manifest.xml') "-outputresource:$exe;#1"
    if ($LASTEXITCODE -ne 0) { throw "mt.exe no pudo incrustar el manifiesto: $LASTEXITCODE" }
    $extracted = Join-Path $out 'manifest-verificado.xml'
    & mt.exe -nologo "-inputresource:$exe;#1" "-out:$extracted"
    if ($LASTEXITCODE -ne 0) { throw "mt.exe no pudo extraer el manifiesto: $LASTEXITCODE" }
    [xml]$actual = Get-Content $extracted -Raw
    $manager = [Xml.XmlNamespaceManager]::new($actual.NameTable)
    $manager.AddNamespace('a','urn:schemas-microsoft-com:asm.v3')
    if ($actual.SelectSingleNode('//a:requestedExecutionLevel',$manager).GetAttribute('level') -ne 'asInvoker') { throw 'El manifiesto incrustado requiere privilegios inesperados.' }
    Remove-Item $extracted
    # El panel no se eleva por completo: UAC se mantiene por accion.

}
foreach ($file in @('README.md','MANUAL.md','BUILD.md','CHANGELOG.md','LICENSE','LICENSE.es.md','SECURITY.md','THIRD_PARTY_NOTICES.md','VERSION.json','install.ps1','uninstall.ps1')) { Copy-Item (Join-Path $root $file) $out -Force }
Copy-Item (Join-Path $root 'Assets\Suite.ico') $out -Force
Copy-Item (Join-Path $PSScriptRoot 'manifest.xml') $out -Force
Copy-Item (Join-Path $PSScriptRoot 'Deployment.Common.ps1') $out -Force
if ($CertificateThumbprint) {
    $toSign = @(Get-ChildItem $out -File | Where-Object Extension -in @('.ps1','.exe') | Select-Object -ExpandProperty FullName)
    & (Join-Path $PSScriptRoot 'Sign-Release.ps1') -FilePath $toSign -CertificateThumbprint $CertificateThumbprint -TimestampServer $TimestampServer
}
if ($Format -eq 'Msi') {
    foreach ($tool in @('candle.exe','light.exe')) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "Falta $tool. Instala WiX Toolset 3.x y agregalo a PATH." }
    }
    $object = Join-Path $out 'Suite.wixobj'
    & candle.exe -nologo -arch x64 "-dSourceDir=$out" "-dProductVersion=$version" -out $object (Join-Path $PSScriptRoot 'Suite.wxs')
    if ($LASTEXITCODE -ne 0) { throw "candle fallo: $LASTEXITCODE" }
    & light.exe -nologo -out (Join-Path $out "AdvancedToolSuite-$version-x64.msi") $object
    if ($LASTEXITCODE -ne 0) { throw "light fallo: $LASTEXITCODE" }
    if ($CertificateThumbprint) {
        & (Join-Path $PSScriptRoot 'Sign-Release.ps1') -FilePath (Join-Path $out "AdvancedToolSuite-$version-x64.msi") -CertificateThumbprint $CertificateThumbprint -TimestampServer $TimestampServer
    }
}
$checksums = @(Get-ChildItem $out -File | Where-Object { $_.Name -ne 'SHA256.json' -and $_.Extension -notin @('.wixobj','.wixpdb') } | ForEach-Object {
    [ordered]@{file=$_.Name; sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash}
})
[ordered]@{version=$version; utc=[DateTime]::UtcNow.ToString('o'); format=$Format; ps2exe=[string]$Ps2ExeVersion; signed=[bool]$CertificateThumbprint; files=$checksums} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $out 'SHA256.json') -Encoding UTF8
$status = if ($CertificateThumbprint) { 'Firma y sello de tiempo verificados' } else { 'SIN FIRMA' }
Write-Output "Distribucion generada en $out / $status. Prueba el paquete en una VM antes de distribuirlo."
