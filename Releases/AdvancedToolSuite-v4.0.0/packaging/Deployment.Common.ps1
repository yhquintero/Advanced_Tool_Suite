#requires -Version 5.1
# Funciones compartidas de instalacion; no ejecuta operaciones al cargarse.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ATSDeployment {
    if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitProcess) { throw 'Usa Windows PowerShell de 64 bits en Windows 10/11.' }
    $windows = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    if ([int]$windows.CurrentBuildNumber -lt 10240 -or $windows.InstallationType -ne 'Client') { throw 'Se requiere Windows 10/11 de escritorio.' }
    $net = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full'
    if ($net.Release -lt 528040) { throw 'Se requiere .NET Framework 4.8 o posterior.' }
    [pscustomobject]@{
        ProductId='AdvancedToolSuite.Nexus'
        Root=(Join-Path $env:LOCALAPPDATA 'Programs\AdvancedToolSuite')
        UninstallKey='HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\AdvancedToolSuite.Nexus'
        Shortcut=(Join-Path ([Environment]::GetFolderPath('Programs')) 'Advanced Tool Suite.lnk')
        Receipt='installed-files.json'
    }
}

function Get-ATSPayloadNames {
    return @('AdvancedToolSuite.ps1','AdvancedToolSuite.exe','uninstall.ps1','install.ps1','Deployment.Common.ps1','Suite.ico','VERSION.json','README.md','MANUAL.md','BUILD.md','CHANGELOG.md','LICENSE','LICENSE.es.md','SECURITY.md','THIRD_PARTY_NOTICES.md','SHA256.json','manifest.xml')
}

function Assert-ATSPlainDirectory([string]$Path) {
    # Rechaza junctions/symlinks en toda la cadena para evitar borrados fuera del destino.
    $item = [IO.Path]::GetFullPath($Path)
    while ($item) {
        if (Test-Path -LiteralPath $item) {
            $attributes = (Get-Item -LiteralPath $item -Force).Attributes
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "No se permiten puntos de reanalisis: $item" }
            if (($attributes -band [IO.FileAttributes]::Directory) -eq 0) { throw "Se esperaba una carpeta: $item" }
        }
        $parent = [IO.Path]::GetDirectoryName($item)
        if ($parent -eq $item) { break }
        $item = $parent
    }
}

function Read-ATSReceipt([string]$Directory) {
    $path = Join-Path $Directory 'installed-files.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'Falta el recibo de instalacion; no se modificara este directorio.' }
    if (((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'El recibo no puede ser un enlace.' }
    $receipt = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    if ($receipt.ProductId -ne 'AdvancedToolSuite.Nexus' -or $receipt.EntryPoint -notin @('AdvancedToolSuite.ps1','AdvancedToolSuite.exe')) { throw 'Recibo de otro producto o no valido.' }
    $names = @()
    foreach ($file in @($receipt.Files)) {
        if ($file.Name -notin (Get-ATSPayloadNames) -or $file.Hash -notmatch '^[A-Fa-f0-9]{64}$' -or $file.Name -in $names) { throw 'Lista de archivos del recibo no valida.' }
        $names += $file.Name
        $installed = Join-Path $Directory $file.Name
        if (Test-Path -LiteralPath $installed) {
            if (((Get-Item -LiteralPath $installed -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Archivo enlazado no permitido: $($file.Name)" }
            if ((Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash -ne $file.Hash) { throw "Archivo modificado: $($file.Name). Conserva una copia y revisa la instalacion antes de continuar." }
        }
    }
    if ($receipt.EntryPoint -notin $names -or 'uninstall.ps1' -notin $names -or 'Deployment.Common.ps1' -notin $names) { throw 'Recibo incompleto.' }
    return $receipt
}

function Assert-ATSPackage([string]$Directory, [switch]$RequireSignature) {
    Assert-ATSPlainDirectory $Directory
    $manifestPath = Join-Path $Directory 'SHA256.json'
    $metadataPath = Join-Path $Directory 'VERSION.json'
    foreach ($requiredPath in @($manifestPath,$metadataPath)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) { throw 'Selecciona una distribucion completa generada por Build-Release, con SHA256.json y VERSION.json.' }
    }
    $hashes = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($hashes.format -eq 'Msi') { throw 'Este paquete debe instalarse con su MSI, no con install.ps1.' }
    $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    if ($metadata.version -notmatch '^\d+\.\d+\.\d+$' -or $hashes.version -ne $metadata.version) { throw 'Version de paquete incoherente.' }
    $entry = if (Test-Path (Join-Path $Directory 'AdvancedToolSuite.exe')) { 'AdvancedToolSuite.exe' } else { 'AdvancedToolSuite.ps1' }
    $files = @()
    $names = @()
    foreach ($file in @($hashes.files)) {
        if ($file.file -notin (Get-ATSPayloadNames) -or $file.file -eq 'SHA256.json' -or $file.file -in $names -or $file.sha256 -notmatch '^[A-Fa-f0-9]{64}$') { throw 'Manifiesto de hashes no valido.' }
        $path = Join-Path $Directory $file.file
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Falta $($file.file)." }
        if (((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Enlace no permitido: $path" }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $file.sha256) { throw "Hash no coincide: $($file.file)." }
        $names += $file.file
        $files += $file.file
        if ($RequireSignature -and [IO.Path]::GetExtension($path) -in @('.ps1','.exe')) {
            if ((Get-AuthenticodeSignature -LiteralPath $path).Status -ne 'Valid') { throw "Firma no valida: $($file.file)." }
        }
    }
    foreach ($required in @($entry,'VERSION.json','uninstall.ps1','Deployment.Common.ps1','install.ps1','Suite.ico')) {
        if ($required -notin $names) { throw "Archivo requerido sin hash: $required" }
    }
    return [pscustomobject]@{EntryPoint=$entry; Version=$metadata.version; Files=@($files + 'SHA256.json')}
}

function Write-ATSDeploymentLog([string]$Message) {
    try {
        $folder = Join-Path $env:LOCALAPPDATA 'AdvancedToolSuite'
        New-Item $folder -ItemType Directory -Force | Out-Null
        $path = Join-Path $folder 'instalacion.log'
        if ((Test-Path $path) -and (Get-Item $path).Length -gt 1048576) { Move-Item $path "$path.1" -Force }
        Add-Content $path ('{0} | {1}' -f [DateTime]::UtcNow.ToString('o'),$Message) -Encoding UTF8
    } catch { Write-Warning 'No se pudo registrar la operacion de instalacion.' }
}

function Get-ATSLaunch([string]$Directory, [string]$EntryPoint) {
    if ($EntryPoint -eq 'AdvancedToolSuite.exe') { return @{Target=(Join-Path $Directory $EntryPoint); Arguments=''} }
    if ($EntryPoint -ne 'AdvancedToolSuite.ps1') { throw 'Punto de entrada no permitido.' }
    return @{Target="$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"; Arguments=('-NoProfile -STA -File "{0}"' -f (Join-Path $Directory $EntryPoint))}
}

function Test-ATSShortcut([string]$Path, $Launch) {
    if (((Get-Item -LiteralPath $Path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'El acceso directo no puede ser un enlace de sistema de archivos.' }
    $shell = New-Object -ComObject WScript.Shell
    try {
        $link = $shell.CreateShortcut($Path)
        try { return $link.TargetPath -eq $Launch.Target -and $link.Arguments -eq $Launch.Arguments }
        finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($link) }
    } finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) }
}
