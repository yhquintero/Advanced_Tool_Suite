#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
foreach ($file in Get-ChildItem $root -Filter '*.ps1' -Recurse | Where-Object FullName -NotMatch '[\\/]artifacts[\\/]') {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        $parseErrors | Format-List | Out-String | Write-Error
        exit 1
    }
    Write-Output ('Sintaxis valida: ' + $file.Name)
}
& (Join-Path $root 'Tool\AdvancedToolSuite.ps1') -ValidateOnly
