#requires -Version 5.1
<# .SYNOPSIS
Firma archivos con un certificado de firma de codigo ya instalado; no importa ni genera claves.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string[]]$FilePath,
    [Parameter(Mandatory)][ValidatePattern('^[a-fA-F0-9]{40}$')][string]$CertificateThumbprint,
    [Parameter(Mandatory)][uri]$TimestampServer
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Authenticode requiere Windows.' }
if ($TimestampServer.Scheme -ne 'https') { throw 'Utiliza un servidor de sello de tiempo HTTPS de confianza.' }
$certificate = Get-Item -LiteralPath "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction Stop
if (-not $certificate.HasPrivateKey) { throw 'El certificado no tiene una clave privada accesible.' }
if ($certificate.NotAfter -le (Get-Date) -or $certificate.NotBefore -gt (Get-Date)) { throw 'El certificado no esta vigente.' }
$ekus = @($certificate.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.37' } | ForEach-Object { $_.EnhancedKeyUsages } | ForEach-Object { $_.Value })
if ('1.3.6.1.5.5.7.3.3' -notin $ekus) { throw 'El certificado no permite firma de codigo.' }
foreach ($file in $FilePath) {
    $resolved = (Resolve-Path -LiteralPath $file).ProviderPath
    if ([IO.Path]::GetExtension($resolved) -notin @('.ps1','.exe','.msi')) { throw "Tipo no permitido para esta receta: $resolved" }
    if ($PSCmdlet.ShouldProcess($resolved,'Firmar con SHA256 y sello de tiempo')) {
        $signature = Set-AuthenticodeSignature -LiteralPath $resolved -Certificate $certificate -HashAlgorithm SHA256 -TimestampServer $TimestampServer.AbsoluteUri
        if ($signature.Status -ne 'Valid') { throw "Firma no valida: $resolved / $($signature.StatusMessage)" }
        if ($null -eq $signature.TimeStamperCertificate) { throw "No se obtuvo sello de tiempo: $resolved" }
        $verified = Get-AuthenticodeSignature -LiteralPath $resolved
        if ($verified.Status -ne 'Valid') { throw "La verificacion posterior fallo: $resolved" }
        Write-Output "Firma y sello verificados: $resolved"
    }
}
