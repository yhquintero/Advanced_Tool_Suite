#requires -Version 5.1
[CmdletBinding()]
param([version]$PesterVersion = '5.7.1')
$ErrorActionPreference = 'Stop'
Import-Module Pester -RequiredVersion $PesterVersion -Force -ErrorAction Stop
$root = Split-Path $PSScriptRoot -Parent
$results = Join-Path $root 'artifacts\tests'
New-Item $results -ItemType Directory -Force | Out-Null
$config = New-PesterConfiguration
$config.Run.Path = Join-Path $PSScriptRoot 'ATS.Tests.ps1'
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = Join-Path $results 'ATS-Pester.xml'
$result = Invoke-Pester -Configuration $config
if ($result.TotalCount -ne 43 -or $result.PassedCount -ne 43 -or $result.FailedCount -gt 0 -or $result.SkippedCount -gt 0) {
    throw "Pester no cumple el contrato: total=$($result.TotalCount), aprobadas=$($result.PassedCount), fallidas=$($result.FailedCount), omitidas=$($result.SkippedCount). Se requieren 43 aprobadas."
}
Write-Output 'Pester: 43/43 casos aprobados.'
