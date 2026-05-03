param(
  [Parameter(Mandatory = $true)]
  [object]$Context
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$bootstrapRoot = [string]$Context.BootstrapRoot
$repoRoot = [string]$Context.RepoRoot

Import-Module (Join-Path $bootstrapRoot "bootstrap.common.psm1") -Force

Write-Step "PowerShell Completions"

$taskPath = Join-Path $bootstrapRoot "tasks\add-pscompletions.ps1"
$manifestPath = Join-Path $repoRoot "manifests\windows.packages.json"

if (-not (Test-Path -LiteralPath $manifestPath))
{
  Write-Warn "Windows package manifest not found: $manifestPath"
  return
}

$windowsPackages = $Context.WindowsPackages

if (
  $null -eq $windowsPackages -or
  -not $windowsPackages.PSObject.Properties["powershellCompletions"] -or
  $null -eq $windowsPackages.powershellCompletions
)
{
  Write-Warn "No powershellCompletions declared in Windows package manifest."
  return
}

& $taskPath `
  -Manifest $manifestPath `
  -Completions @($windowsPackages.powershellCompletions)
