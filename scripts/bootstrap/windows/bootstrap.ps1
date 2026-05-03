#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows developer environment bootstrap entrypoint.
.DESCRIPTION
    This is the orchestrator only.
    It loads the shared module, prepares a bootstrap context, reads manifests,
    then executes step scripts in order.

    Boundary of this script:
      - prepares environment prerequisites
      - installs/configures Scoop and selected Scoop groups
      - configures mise and installs runtimes
      - optionally installs VS Code extensions

    It does NOT:
      - auto-create ~/.config/chezmoi/chezmoi.toml
      - auto-run chezmoi init/apply
      - auto-sync PowerShell profile

    Those are now manual follow-up steps, especially because they may depend on
    Bitwarden secrets and user confirmation.
.NOTES
    Run with:
      Set-ExecutionPolicy Bypass -Scope Process -Force
      .\scripts\bootstrap.ps1
#>

param(
  # Skip the VS Code extensions step.
  [switch]$SkipVSCode,

  # Skip the mise config/runtime step.
  [switch]$SkipMise,

  # Skip the cargo packages step.
  [switch]$SkipCargo,

  # Skip the PowerShell completions step.
  [switch]$SkipPSCompletions,

  # Optional hint shown in the final manual chezmoi steps.
  [string]$ChezmoiRepo = "",

  # Reserved for later optional Dev Drive step.
  [string]$DevDrive = ""
)

$ErrorActionPreference = "Stop"

# Load shared helpers used by all steps.
Import-Module (Join-Path $PSScriptRoot "bootstrap.common.psm1") -Force

# Create a shared context object so step scripts do not need to recompute paths
# or re-read manifests independently.
$context = New-BootstrapContext `
  -BootstrapRoot $PSScriptRoot `
  -ChezmoiRepo $ChezmoiRepo `
  -DevDrive $DevDrive `
  -SkipChezmoi $true

# Preconditions that should fail fast before any side effects happen.
Assert-RunningAsAdministrator

# Repo root is used as the source of manifests and step scripts.
$repoRoot = $context.RepoRoot

# Read manifests once and share them across all steps.
$context.WindowsPackages = Get-ManifestJson `
  -RepoRoot $repoRoot `
  -RelativePath "manifests\windows.packages.json"

$context.WindowsRuntimes = Get-ManifestJson `
  -RepoRoot $repoRoot `
  -RelativePath "manifests\windows.runtimes.json"

$context.CargoPackages = Get-ManifestJson `
  -RepoRoot $repoRoot `
  -RelativePath "manifests\cargo.packages.json"

# New bootstrap only supports the scoopGroups-based manifest structure.
Assert-ManifestHasScoopGroups -WindowsPackages $context.WindowsPackages

# Ordered execution plan.
# Each step receives the same Context object.
$steps = @(
  "steps\00-preflight.ps1",
  "steps\05-xdg-env.ps1",
  "steps\10-scoop-core.ps1",
  "steps\15-bootstrap-required.ps1",
  "steps\20-scoop-groups.ps1"
)

if (-not $SkipMise)
{
  $steps += "steps\40-mise.ps1"
}

if (-not $SkipCargo)
{
  $steps += "steps\50-cargo-packages.ps1"
}

if (-not $SkipPSCompletions)
{
  $steps += "steps\60-pscompletions.ps1"
}

if (-not $SkipVSCode)
{
  $steps += "steps\70-vscode.ps1"
}

foreach ($relativeStep in $steps)
{
  $stepPath = Join-Path $PSScriptRoot $relativeStep

  if (-not (Test-Path $stepPath))
  {
    throw "Bootstrap step not found: $stepPath"
  }

  try
  {
    & $stepPath -Context $context
  } catch
  {
    $msg = $_.Exception.Message
    $stack = $_.ScriptStackTrace
    throw "Bootstrap step failed: $relativeStep`n$msg`n$stack"
  }
}

# Final summary.
Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "  ✓  Bootstrap completed" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green

# Surface manual next steps instead of auto-running chezmoi.
Write-Host ""
Write-Host (Get-ManualChezmoiNextSteps -RepoHint $ChezmoiRepo) -ForegroundColor White

if ($SkipMise)
{
  Write-Warn "mise step was skipped."
}

if ($SkipCargo)
{
  Write-Warn "cargo step was skipped."
}

if ($SkipPSCompletions)
{
  Write-Warn "PowerShell completions step was skipped."
}

if ($SkipVSCode)
{
  Write-Warn "VS Code extensions step was skipped."
}
