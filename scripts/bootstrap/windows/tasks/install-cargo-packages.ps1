# install-cargo-packages.ps1

# Install Cargo packages selected by the Windows bootstrap flow.

# Strategy:
# - Bootstrap cargo-binstall first with cargo install --locked.
# - For crates.io packages, prefer:
#     cargo binstall --no-confirm --disable-strategies compile <name>
# - If no prebuilt binary is available, fall back to:
#     cargo install --locked <name>
# - For git packages, use:
#     cargo install --locked --git <url> --rev <rev> <name>

# Notes:
# - Optional package selection is handled by steps/50-cargo-packages.ps1.
# - This task only installs the package objects it receives.
# - When executed directly without -Packages, it installs all Windows-supported
#   packages from manifests/cargo.packages.json.

param(
  [string]$Manifest = "",

  [object[]]$Packages = @(),

  # Reinstall packages even if cargo install --list already contains them.
  [switch]$Force,

  # Print commands without executing them.
  [switch]$DryRun,

  # Do not pass --version to crates.io installs.
  [switch]$NoVersionPin
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$bootstrapRoot = Split-Path -Parent $PSScriptRoot

function Write-TaskStep
{
  param([string]$Message)

  Write-Host ""
  Write-Host "━━━ $Message ━━━" -ForegroundColor Cyan
}

function Write-TaskOk
{
  param([string]$Message)

  Write-Host " ✓ $Message" -ForegroundColor Green
}

function Write-TaskWarn
{
  param([string]$Message)

  Write-Host " ⚠ $Message" -ForegroundColor Yellow
}

function Test-CommandExists
{
  param([string]$Command)

  return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Add-PathEntry
{
  param([string]$PathEntry)

  if ([string]::IsNullOrWhiteSpace($PathEntry))
  {
    return
  }

  if (-not (Test-Path -LiteralPath $PathEntry))
  {
    return
  }

  $currentEntries = @(
    $env:Path -split ";" |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  )

  $normalizedTarget = [System.IO.Path]::GetFullPath($PathEntry)

  foreach ($entry in $currentEntries)
  {
    try
    {
      if ([System.IO.Path]::GetFullPath($entry).Equals($normalizedTarget, [System.StringComparison]::OrdinalIgnoreCase))
      {
        return
      }
    } catch
    {
      # Ignore malformed PATH entries.
    }
  }

  $env:Path = "$PathEntry;$env:Path"
}

function Get-CargoBinDirs
{
  $dirs = @()

  if (-not [string]::IsNullOrWhiteSpace($env:CARGO_HOME))
  {
    $dirs += Join-Path $env:CARGO_HOME "bin"
  }

  if (-not [string]::IsNullOrWhiteSpace($HOME))
  {
    $dirs += Join-Path $HOME ".cargo\bin"
  }

  if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE))
  {
    $dirs += Join-Path $env:USERPROFILE ".cargo\bin"
  }

  return @(
    $dirs |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
      Select-Object -Unique
  )
}

function Update-PathEnvironment
{
  $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
  $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

  $paths = @(
    $machinePath
    $userPath
    $env:Path
  ) | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_)
  }

  $env:Path = ($paths -join ";")

  foreach ($cargoBinDir in Get-CargoBinDirs)
  {
    Add-PathEntry -PathEntry $cargoBinDir
  }
}

function Get-RepoRoot
{
  param([string]$StartPath)

  $current = (Resolve-Path $StartPath).Path

  while (-not [string]::IsNullOrWhiteSpace($current))
  {
    $manifestPath = Join-Path $current "manifests\cargo.packages.json"

    if (Test-Path -LiteralPath $manifestPath)
    {
      return $current
    }

    $parent = Split-Path $current -Parent

    if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current)
    {
      break
    }

    $current = $parent
  }

  throw "Could not locate repo root from '$StartPath'."
}

function Get-PropertyValue
{
  param(
    [object]$Object,
    [string]$Name,
    [object]$Fallback = $null
  )

  if ($null -ne $Object -and $Object.PSObject.Properties[$Name])
  {
    return $Object.$Name
  }

  return $Fallback
}

function Get-PackagePriority
{
  param([object]$Package)

  $value = Get-PropertyValue -Object $Package -Name "installPriority" -Fallback 500

  try
  {
    return [int]$value
  } catch
  {
    return 500
  }
}

function Test-PackageSupportsWindows
{
  param([object]$Package)

  if (-not $Package.PSObject.Properties["os"])
  {
    return $true
  }

  return @($Package.os) -contains "windows"
}

function Get-CargoInstalledPackageMap
{
  $installed = @{}

  try
  {
    $installedLines = @(cargo install --list)
  } catch
  {
    return $installed
  }

  foreach ($line in $installedLines)
  {
    if ($line -match '^([^\s]+)\s+v([^\s:]+)(?:\s+\((.+)\))?:$')
    {
      $name = [string]$matches[1]
      $version = [string]$matches[2]
      $source = $null

      if ($matches.Count -ge 4)
      {
        $source = [string]$matches[3]
      }

      $installed[$name] = [pscustomobject]@{
        Name = $name
        Version = $version
        Source = $source
      }
    }
  }

  return $installed
}

function Test-CargoBinstallAvailable
{
  Update-PathEnvironment

  if (Get-Command cargo-binstall -ErrorAction SilentlyContinue)
  {
    return $true
  }

  try
  {
    & cargo binstall --version *> $null
    return $LASTEXITCODE -eq 0
  } catch
  {
    return $false
  }
}

function Format-NativeCommand
{
  param(
    [string]$FilePath,
    [string[]]$CommandArguments
  )

  $parts = @($FilePath)

  foreach ($argument in $CommandArguments)
  {
    if ($argument -match '\s')
    {
      $parts += '"' + ($argument -replace '"', '\"') + '"'
    } else
    {
      $parts += $argument
    }
  }

  return ($parts -join " ")
}

function Invoke-NativeCommand
{
  param(
    [string]$FilePath,
    [string[]]$CommandArguments,
    [switch]$AllowFailure
  )

  $commandText = Format-NativeCommand -FilePath $FilePath -CommandArguments $CommandArguments

  if ($DryRun)
  {
    Write-Host " DRY-RUN: $commandText" -ForegroundColor DarkGray
    return 0
  }

  Write-Host " → $commandText" -ForegroundColor Gray

  & $FilePath @CommandArguments
  $exitCode = if ($null -ne $LASTEXITCODE)
  { [int]$LASTEXITCODE 
  } else
  { 0 
  }

  if ($exitCode -ne 0 -and -not $AllowFailure)
  {
    throw "Command failed with exit code $exitCode`: $commandText"
  }

  return $exitCode
}

function Get-CratesIoInstallArguments
{
  param(
    [object]$Package,
    [switch]$UseBinstall
  )

  $name = [string]$Package.name
  $version = Get-PropertyValue -Object $Package -Name "version" -Fallback ""

  if ($UseBinstall)
  {
    $commandArguments = @(
      "binstall",
      "--no-confirm",
      "--disable-strategies",
      "compile"
    )

    if (-not $NoVersionPin -and -not [string]::IsNullOrWhiteSpace($version))
    {
      $commandArguments += @("--version", $version)
    }

    $commandArguments += $name
    return $commandArguments
  }

  $installArguments = @(
    "install",
    "--locked"
  )

  if ($Force)
  {
    $installArguments += "--force"
  }

  if (-not $NoVersionPin -and -not [string]::IsNullOrWhiteSpace($version))
  {
    $installArguments += @("--version", $version)
  }

  $installArguments += $name
  return $installArguments
}

function Get-GitInstallArguments
{
  param([object]$Package)

  $name = [string]$Package.name
  $git = [string]$Package.git
  $rev = Get-PropertyValue -Object $Package -Name "rev" -Fallback ""

  $installArguments = @(
    "install",
    "--locked"
  )

  if ($Force)
  {
    $installArguments += "--force"
  }

  $installArguments += @("--git", $git)

  if (-not [string]::IsNullOrWhiteSpace($rev))
  {
    $installArguments += @("--rev", [string]$rev)
  }

  $installArguments += $name
  return $installArguments
}

function Install-CargoBinstallBootstrap
{
  param(
    [object]$CargoBinstallPackage,
    [hashtable]$InstalledMap
  )

  Update-PathEnvironment

  if (Test-CargoBinstallAvailable)
  {
    Write-TaskOk "cargo-binstall already available"
    return
  }

  if ($InstalledMap.ContainsKey("cargo-binstall"))
  {
    Write-TaskOk "cargo-binstall already installed"
    Update-PathEnvironment

    if (Test-CargoBinstallAvailable)
    {
      Write-TaskOk "cargo-binstall is now available"
      return
    }

    $cargoBinDirs = @(Get-CargoBinDirs) -join ", "

    throw @"
cargo-binstall is installed according to 'cargo install --list',
but it is not available as either 'cargo-binstall' or 'cargo binstall'.

This usually means the current elevated shell does not have Cargo's bin directory in PATH.

Checked Cargo bin directories:
  $cargoBinDirs

Current PATH:
  $env:Path

Fix PATH for the current bootstrap environment, then rerun bootstrap.
"@
  }

  Write-TaskStep "Bootstrapping cargo-binstall"

  if ($null -eq $CargoBinstallPackage)
  {
    $CargoBinstallPackage = [pscustomobject]@{
      name = "cargo-binstall"
      version = ""
    }
  }

  $installArguments = Get-CratesIoInstallArguments -Package $CargoBinstallPackage -UseBinstall:$false
  Invoke-NativeCommand -FilePath "cargo" -CommandArguments $installArguments | Out-Null

  Update-PathEnvironment
  $updatedInstalledMap = Get-CargoInstalledPackageMap

  if (-not $updatedInstalledMap.ContainsKey("cargo-binstall"))
  {
    throw "cargo-binstall bootstrap finished, but 'cargo install --list' does not contain cargo-binstall."
  }

  if (-not (Test-CargoBinstallAvailable))
  {
    $cargoBinDirs = @(Get-CargoBinDirs) -join ", "

    throw @"
cargo-binstall was installed, but it is not available as either 'cargo-binstall' or 'cargo binstall'.

Checked Cargo bin directories:
  $cargoBinDirs

Current PATH:
  $env:Path

Fix PATH for the current bootstrap environment, then rerun bootstrap.
"@
  }

  Write-TaskOk "cargo-binstall bootstrapped"
}

function Install-CargoPackage
{
  param(
    [object]$Package,
    [hashtable]$InstalledMap
  )

  $name = [string]$Package.name
  $isInstalled = $InstalledMap.ContainsKey($name)

  if ($isInstalled -and -not $Force)
  {
    Write-TaskOk "$name already installed"

    return [pscustomobject]@{
      Name = $name
      Status = "skipped"
      Method = ""
    }
  }

  if ($Package.PSObject.Properties["git"])
  {
    Write-Host " → Installing $name from git..." -ForegroundColor Gray

    $installArguments = Get-GitInstallArguments -Package $Package
    Invoke-NativeCommand -FilePath "cargo" -CommandArguments $installArguments | Out-Null

    return [pscustomobject]@{
      Name = $name
      Status = "installed"
      Method = "cargo install --git"
    }
  }

  if ($name -eq "cargo-binstall")
  {
    Write-Host " → Installing $name with cargo install..." -ForegroundColor Gray

    $installArguments = Get-CratesIoInstallArguments -Package $Package -UseBinstall:$false
    Invoke-NativeCommand -FilePath "cargo" -CommandArguments $installArguments | Out-Null

    return [pscustomobject]@{
      Name = $name
      Status = "installed"
      Method = "cargo install"
    }
  }

  if (-not (Test-CargoBinstallAvailable))
  {
    throw "cargo-binstall is required for installing '$name' with prebuilt-binary strategy, but it is not available."
  }

  Write-Host " → Installing $name with cargo binstall..." -ForegroundColor Gray

  $binstallArguments = Get-CratesIoInstallArguments -Package $Package -UseBinstall:$true
  $binstallExitCode = Invoke-NativeCommand -FilePath "cargo" -CommandArguments $binstallArguments -AllowFailure

  if ($binstallExitCode -eq 0)
  {
    return [pscustomobject]@{
      Name = $name
      Status = "installed"
      Method = "cargo binstall"
    }
  }

  Write-TaskWarn "cargo binstall failed for $name; falling back to cargo install --locked"

  $installArguments = Get-CratesIoInstallArguments -Package $Package -UseBinstall:$false
  Invoke-NativeCommand -FilePath "cargo" -CommandArguments $installArguments | Out-Null

  return [pscustomobject]@{
    Name = $name
    Status = "installed"
    Method = "cargo install fallback"
  }
}

function Resolve-SelectedPackages
{
  if ($Packages.Count -gt 0)
  {
    return @(
      $Packages |
        Where-Object { Test-PackageSupportsWindows -Package $_ } |
        Sort-Object `
        @{ Expression = { Get-PackagePriority -Package $_ } }, `
        @{ Expression = { [string]$_.name } }
    )
  }

  $repoRoot = Get-RepoRoot -StartPath $bootstrapRoot

  if ([string]::IsNullOrWhiteSpace($Manifest))
  {
    $Manifest = Join-Path $repoRoot "manifests\cargo.packages.json"
  }

  $manifestPath = [System.IO.Path]::GetFullPath($Manifest)

  if (-not (Test-Path -LiteralPath $manifestPath))
  {
    throw "Cargo packages manifest not found: $manifestPath"
  }

  $manifestObject = Get-Content $manifestPath -Raw | ConvertFrom-Json -Depth 30

  if (-not $manifestObject.PSObject.Properties["cargoPackages"])
  {
    throw "Manifest does not contain cargoPackages: $manifestPath"
  }

  return @(
    $manifestObject.cargoPackages |
      Where-Object { Test-PackageSupportsWindows -Package $_ } |
      Sort-Object `
      @{ Expression = { Get-PackagePriority -Package $_ } }, `
      @{ Expression = { [string]$_.name } }
  )
}

function Resolve-CargoBinstallPackage
{
  param([object[]]$SelectedPackages)

  $candidate = @(
    $SelectedPackages |
      Where-Object { [string]$_.name -eq "cargo-binstall" } |
      Select-Object -First 1
  )

  if ($candidate.Count -gt 0)
  {
    return $candidate[0]
  }

  if (-not [string]::IsNullOrWhiteSpace($Manifest) -and (Test-Path -LiteralPath $Manifest))
  {
    $manifestObject = Get-Content $Manifest -Raw | ConvertFrom-Json -Depth 30

    if ($manifestObject.PSObject.Properties["cargoPackages"])
    {
      $manifestCandidate = @(
        $manifestObject.cargoPackages |
          Where-Object { [string]$_.name -eq "cargo-binstall" } |
          Select-Object -First 1
      )

      if ($manifestCandidate.Count -gt 0)
      {
        return $manifestCandidate[0]
      }
    }
  }

  return [pscustomobject]@{
    name = "cargo-binstall"
    version = ""
  }
}

# Verify cargo.

Update-PathEnvironment

if (-not (Test-CommandExists "cargo"))
{
  throw "cargo command not found. Install Rust first, then rerun this task."
}

# Resolve package plan.

$selectedPackages = @(Resolve-SelectedPackages)

if ($selectedPackages.Count -eq 0)
{
  Write-TaskWarn "No Cargo packages selected for installation."
  exit 0
}

# Install.

Write-TaskStep "Installing Cargo Packages ($($selectedPackages.Count) selected)"

$installedMap = Get-CargoInstalledPackageMap
$cargoBinstallPackage = Resolve-CargoBinstallPackage -SelectedPackages $selectedPackages

Install-CargoBinstallBootstrap `
  -CargoBinstallPackage $cargoBinstallPackage `
  -InstalledMap $installedMap

$installedMap = Get-CargoInstalledPackageMap
$results = @()
$failed = @()

foreach ($package in $selectedPackages)
{
  try
  {
    $result = Install-CargoPackage -Package $package -InstalledMap $installedMap
    $results += $result

    if ($result.Status -eq "installed")
    {
      $installedMap[[string]$package.name] = [pscustomobject]@{
        Name = [string]$package.name
        Version = Get-PropertyValue -Object $package -Name "version" -Fallback ""
        Source = Get-PropertyValue -Object $package -Name "source" -Fallback ""
      }

      Write-TaskOk "$($package.name) [$($result.Method)]"
    }
  } catch
  {
    Write-TaskWarn "Failed to install $($package.name): $($_.Exception.Message)"

    $failed += [pscustomobject]@{
      Name = [string]$package.name
      Error = $_.Exception.Message
    }
  }
}

# Summary.

$installedCount = @($results | Where-Object { $_.Status -eq "installed" }).Count
$skippedCount = @($results | Where-Object { $_.Status -eq "skipped" }).Count

Write-Host ""
Write-Host "─────────────────────────────────" -ForegroundColor DarkGray
Write-TaskOk "Installed : $installedCount"
Write-Host " · Skipped : $skippedCount (already present)" -ForegroundColor DarkGray

if ($failed.Count -gt 0)
{
  Write-Host ""
  Write-TaskWarn "Failed to install $($failed.Count) Cargo package(s):"

  foreach ($item in $failed)
  {
    Write-TaskWarn " · $($item.Name): $($item.Error)"
  }

  exit 1
}
