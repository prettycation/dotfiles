param(
    [Parameter(Mandatory = $true)]
    $Context
)

$ErrorActionPreference = "Stop"

Write-Step "Preflight Checks"

# 1) 基础路径检查
if ([string]::IsNullOrWhiteSpace($Context.BootstrapRoot) -or -not (Test-Path $Context.BootstrapRoot)) {
    throw "BootstrapRoot is invalid: '$($Context.BootstrapRoot)'"
}

if ([string]::IsNullOrWhiteSpace($Context.RepoRoot) -or -not (Test-Path $Context.RepoRoot)) {
    throw "RepoRoot is invalid: '$($Context.RepoRoot)'"
}

Write-OK "Bootstrap root: $($Context.BootstrapRoot)"
Write-OK "Repo root: $($Context.RepoRoot)"

# 2) Manifest 检查
if ($null -eq $Context.WindowsPackages) {
    throw "WindowsPackages manifest was not loaded into the bootstrap context."
}

if ($null -eq $Context.WindowsRuntimes) {
    throw "WindowsRuntimes manifest was not loaded into the bootstrap context."
}

Write-OK "windows.packages.json loaded"
Write-OK "windows.runtimes.json loaded"

# 3) 新 manifest 结构检查
Assert-ManifestHasScoopGroups -WindowsPackages $Context.WindowsPackages
Write-OK "Manifest uses scoopGroups structure"

# 4) 执行策略检查（这里只提示，不在本步骤里修改）
try {
    $effectivePolicy = Get-ExecutionPolicy
    Write-Host "  Effective execution policy: $effectivePolicy" -ForegroundColor DarkGray
} catch {
    Write-Warn "Could not read current execution policy."
}

# 5) Scoop 可用性检查
if (-not (Test-CommandExists "scoop")) {
    throw @"
Scoop is not available on PATH.

Bootstrap now assumes Scoop is already installed and working.
Please install Scoop manually first, then re-run bootstrap.

Suggested manual checks:
  scoop --version
  scoop bucket list
"@
}

Write-OK "Scoop is available"

# 6) Scoop 基本连通性/可用性探测
try {
    scoop --version *> $null
    Write-OK "Scoop command is functional"
} catch {
    Write-Warn "Scoop failed its version check."
    throw "Scoop exists on PATH but failed to run correctly: $_"
}

# 7) Git 仅做提示，不强制
if (Test-CommandExists "git") {
    Write-OK "Git is available"
} else {
    Write-Warn "Git is not currently available on PATH."
    Write-Warn "This is acceptable if the repo was downloaded as a ZIP, but Git-related workflows will not work until git is installed."
}

# 8) PowerShell 版本提示
$currentPSEdition= $PSVersionTable.PSEdition
$currentPSVersion = $PSVersionTable.PSVersion.ToString()
Write-Host "  Current PowerShell: $currentPSEdition $currentPSVersion" -ForegroundColor DarkGray

if (-not (Test-CommandExists "pwsh")) {
    Write-Warn "PowerShell 7 (pwsh) is not currently available."
    Write-Warn "A later bootstrap step may install it and ask you to restart under pwsh."
} else {
    Write-OK "pwsh is already available"
}

# 9) chezmoi / bw 仅做状态提示，不自动执行
if (Test-CommandExists "chezmoi") {
    $chezmoiSource = Get-ChezmoiSourcePath
    if ([string]::IsNullOrWhiteSpace($chezmoiSource)) {
        Write-Host "  chezmoi is installed but not initialized yet." -ForegroundColor DarkGray
    } else {
        Write-Host "  chezmoi source: $chezmoiSource" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  chezmoi is not installed yet (expected if it will be installed from bootstrap-core-cli)." -ForegroundColor DarkGray
}

if (Test-CommandExists "bw") {
    Write-Host "  Bitwarden CLI (bw) is already available." -ForegroundColor DarkGray
} else {
    Write-Host "  Bitwarden CLI (bw) is not installed yet (expected if it will be installed from bootstrap-core-cli)." -ForegroundColor DarkGray
}

Write-OK "Preflight checks passed"
