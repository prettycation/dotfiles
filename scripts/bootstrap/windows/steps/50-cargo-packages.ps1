param(
  [Parameter(Mandatory = $true)]
  [object]$Context
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$bootstrapRoot = [string]$Context.BootstrapRoot

Import-Module (Join-Path $bootstrapRoot "bootstrap.common.psm1") -Force

Write-Step "Installing Cargo Packages"

$cargoManifest = $Context.CargoPackages

if ($null -eq $cargoManifest)
{
  Write-Warn "Context.CargoPackages is null."
  return
}

if (
  -not $cargoManifest.PSObject.Properties["cargoPackages"] -or
  $null -eq $cargoManifest.cargoPackages
)
{
  Write-Warn "Cargo package manifest does not contain cargoPackages."
  return
}

function Get-ObjectPropValue
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

function Read-IndexSelection
{
  param(
    [Parameter(Mandatory = $true)]
    [object[]]$Items,

    [Parameter(Mandatory = $true)]
    [string]$Prompt,

    [switch]$AllowEmpty
  )

  if ($Items.Count -eq 0)
  {
    return @()
  }

  while ($true)
  {
    $raw = Read-Host $Prompt

    if ([string]::IsNullOrWhiteSpace($raw))
    {
      if ($AllowEmpty)
      {
        return @()
      }

      Write-Warn "Please enter at least one selection."
      continue
    }

    if ($raw -match '^[Aa]$')
    {
      return @(0..($Items.Count - 1))
    }

    $selectedMap = @{}

    try
    {
      $tokens = @(
        $raw -split "," |
          ForEach-Object { $_.Trim() } |
          Where-Object { $_ }
      )

      foreach ($token in $tokens)
      {
        if ($token -match "^(\d+)-(\d+)$")
        {
          $start = [int]$matches[1]
          $end = [int]$matches[2]

          if ($start -gt $end)
          {
            $tmp = $start
            $start = $end
            $end = $tmp
          }

          for ($i = $start; $i -le $end; $i++)
          {
            if ($i -lt 1 -or $i -gt $Items.Count)
            {
              throw "Selection '$i' out of range."
            }

            $selectedMap[$i - 1] = $true
          }
        } elseif ($token -match "^\d+$")
        {
          $index = [int]$token

          if ($index -lt 1 -or $index -gt $Items.Count)
          {
            throw "Selection '$index' out of range."
          }

          $selectedMap[$index - 1] = $true
        } else
        {
          throw "Invalid token '$token'."
        }
      }

      return @(
        $selectedMap.Keys |
          ForEach-Object { [int]$_ } |
          Sort-Object
      )
    } catch
    {
      Write-Warn $_
      Write-Host "  Use numbers like: 1,3,5-7 or A for all." -ForegroundColor DarkGray
    }
  }
}

function Get-CargoPackagePriority
{
  param([object]$Package)

  $value = Get-ObjectPropValue -Object $Package -Name "installPriority" -Fallback 500

  try
  {
    return [int]$value
  } catch
  {
    return 500
  }
}

function Test-CargoPackageSupportsWindows
{
  param([object]$Package)

  if (-not $Package.PSObject.Properties["os"])
  {
    return $true
  }

  return @($Package.os) -contains "windows"
}

function Test-CargoPackageOptional
{
  param([object]$Package)

  if (-not $Package.PSObject.Properties["optional"])
  {
    return $false
  }

  return [bool]$Package.optional
}

function Resolve-SelectedCargoPackages
{
  param(
    [Parameter(Mandatory = $true)]
    [object[]]$Packages
  )

  $windowsPackages = @(
    $Packages |
      Where-Object { Test-CargoPackageSupportsWindows -Package $_ } |
      Sort-Object `
      @{ Expression = { Get-CargoPackagePriority -Package $_ } }, `
      @{ Expression = { [string]$_.name } }
  )

  if ($windowsPackages.Count -eq 0)
  {
    return @()
  }

  $requiredPackages = @(
    $windowsPackages |
      Where-Object { -not (Test-CargoPackageOptional -Package $_) }
  )

  $optionalPackages = @(
    $windowsPackages |
      Where-Object { Test-CargoPackageOptional -Package $_ }
  )

  $selectedPackages = @($requiredPackages)

  if ($requiredPackages.Count -gt 0)
  {
    Write-Host " Required Cargo packages:" -ForegroundColor Gray

    foreach ($pkg in $requiredPackages)
    {
      Write-Host ("  - {0}" -f $pkg.name) -ForegroundColor White
    }
  }

  if ($optionalPackages.Count -gt 0)
  {
    Write-Host ""
    Write-Host " Optional Cargo packages:" -ForegroundColor Gray

    for ($i = 0; $i -lt $optionalPackages.Count; $i++)
    {
      $pkg = $optionalPackages[$i]
      $notes = Get-ObjectPropValue -Object $pkg -Name "notes" -Fallback ""

      if ([string]::IsNullOrWhiteSpace([string]$notes))
      {
        $notes = if ($pkg.PSObject.Properties["git"])
        { "git"
        } else
        { "crates.io"
        }
      }

      Write-Host (
        " [{0}] {1} ({2})" -f
        ($i + 1),
        $pkg.name,
        $notes
      ) -ForegroundColor White

    }

    $includeIndices = Read-IndexSelection `
      -Items $optionalPackages `
      -Prompt "Select optional Cargo packages to install [Enter=none, numbers, A=all]" `
      -AllowEmpty

    foreach ($index in $includeIndices)
    {
      $selectedPackages += $optionalPackages[$index]
    }
  }

  return @(
    $selectedPackages |
      Sort-Object `
      @{ Expression = { Get-CargoPackagePriority -Package $_ } }, `
      @{ Expression = { [string]$_.name } }
  )
}

$selectedPackages = @(
  Resolve-SelectedCargoPackages -Packages @($cargoManifest.cargoPackages)
)

if ($selectedPackages.Count -eq 0)
{
  Write-Host " No Cargo packages selected." -ForegroundColor DarkGray
  Write-OK "Cargo package installation complete"
  return
}

$taskPath = Join-Path $bootstrapRoot "tasks\install-cargo-packages.ps1"

if (-not (Test-Path -LiteralPath $taskPath))
{
  throw "Cargo package install task not found: $taskPath"
}

& $taskPath -Packages $selectedPackages
