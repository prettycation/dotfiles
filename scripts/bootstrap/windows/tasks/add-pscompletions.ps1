# add-pscompletions.ps1

# Add PSCompletions entries declared in manifests/windows.packages.json.

# Expected manifest shape:
# {
#   "powershellCompletions": [
#     { "completion": "git", "alias": "git" },
#     { "completion": "cargo", "alias": "cargo" }
#   ]
# }

# Notes:
# - This bootstrap runs under a strict bootstrap flow.
# - PSCompletions currently reads dynamic properties internally and can fail
#   under StrictMode with errors such as missing '__need_update_data'.
# - To avoid leaking bootstrap StrictMode into PSCompletions, all psc calls are
#   executed in a clean child pwsh -NoProfile process.
# - PowerShell expandable strings require ${var} when a variable is immediately
#   followed by a colon, e.g. "${exitCode}: ...".

param(
  [string]$Manifest = "",

  [object[]]$Completions = @(),

  # Re-add completions even if psc list already contains them.
  [switch]$Force,

  # Print commands without executing them.
  [switch]$DryRun
)

Set-StrictMode -Off
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

function Get-RepoRoot
{
  param([string]$StartPath)

  $current = (Resolve-Path $StartPath).Path

  while (-not [string]::IsNullOrWhiteSpace($current))
  {
    $manifestPath = Join-Path $current "manifests\windows.packages.json"

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

function Format-Command
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

function ConvertTo-Base64Command
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$Command
  )

  $bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
  return [Convert]::ToBase64String($bytes)
}

function Invoke-CleanPwsh
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$Command,

    [switch]$AllowFailure
  )

  $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue

  if ($null -eq $pwsh)
  {
    throw "pwsh is required to run PSCompletions in an isolated process."
  }

  $encodedCommand = ConvertTo-Base64Command -Command $Command

  $commandText = Format-Command `
    -FilePath "pwsh" `
    -CommandArguments @("-NoLogo", "-NoProfile", "-NonInteractive", "-EncodedCommand", $encodedCommand)

  if ($DryRun)
  {
    Write-Host " DRY-RUN: $commandText" -ForegroundColor DarkGray

    return [pscustomobject]@{
      ExitCode = 0
      Output = @()
    }
  }

  $output = @(
    & $pwsh.Source `
      -NoLogo `
      -NoProfile `
      -NonInteractive `
      -EncodedCommand $encodedCommand 2>&1
  )

  $exitCode = if ($null -ne $LASTEXITCODE)
  { [int]$LASTEXITCODE 
  } else
  { 0 
  }

  if ($exitCode -ne 0 -and -not $AllowFailure)
  {
    $message = ($output | ForEach-Object { [string]$_ }) -join "`n"

    throw @"
Command failed with exit code ${exitCode}:
$commandText

Output:
$message
"@
  }

  return [pscustomobject]@{
    ExitCode = $exitCode
    Output = $output
  }
}

function Get-MarkedJsonFromOutput
{
  param(
    [object[]]$Output
  )

  $lines = @(
    $Output |
      ForEach-Object { [string]$_ }
  )

  $beginIndex = -1
  $endIndex = -1

  for ($i = 0; $i -lt $lines.Count; $i++)
  {
    if ($lines[$i] -eq "@@PSC_JSON_BEGIN@@")
    {
      $beginIndex = $i
      continue
    }

    if ($lines[$i] -eq "@@PSC_JSON_END@@")
    {
      $endIndex = $i
      break
    }
  }

  if ($beginIndex -lt 0 -or $endIndex -lt 0 -or $endIndex -le $beginIndex)
  {
    return ""
  }

  return @(
    $lines[($beginIndex + 1)..($endIndex - 1)] |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  ) -join "`n"
}

function Invoke-PscJson
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$PscExpression,

    [switch]$AllowFailure
  )

  $command = @"
`$ErrorActionPreference = 'Stop'
Set-StrictMode -Off
Import-Module PSCompletions -Force -ErrorAction Stop
`$result = @($PscExpression)
`$json = `$result | ConvertTo-Json -Depth 50 -Compress
'@@PSC_JSON_BEGIN@@'
`$json
'@@PSC_JSON_END@@'
"@

  $result = Invoke-CleanPwsh -Command $command -AllowFailure:$AllowFailure

  if ($null -eq $result -or $result.ExitCode -ne 0)
  {
    return $null
  }

  $jsonText = Get-MarkedJsonFromOutput -Output $result.Output

  if ([string]::IsNullOrWhiteSpace($jsonText))
  {
    return @()
  }

  try
  {
    return @($jsonText | ConvertFrom-Json)
  } catch
  {
    $rawOutput = ($result.Output | ForEach-Object { [string]$_ }) -join "`n"

    throw @"
Failed to parse PSCompletions JSON output.

Extracted JSON:
$jsonText

Raw output:
$rawOutput

Original error:
$($_.Exception.Message)
"@
  }
}

function Invoke-PscAdd
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$Completion,

    [string]$Alias = "",

    [switch]$AllowFailure
  )

  $completionLiteral = $Completion.Replace("'", "''")
  $aliasLiteral = $Alias.Replace("'", "''")

  if ([string]::IsNullOrWhiteSpace($Alias) -or $Alias -eq $Completion)
  {
    $pscExpression = "psc add '$completionLiteral'"
  } else
  {
    $pscExpression = "psc add '$completionLiteral' '$aliasLiteral'"
  }

  $command = @"
`$ErrorActionPreference = 'Stop'
Set-StrictMode -Off
Import-Module PSCompletions -Force -ErrorAction Stop
$pscExpression
"@

  $result = Invoke-CleanPwsh -Command $command -AllowFailure:$AllowFailure

  if ($null -eq $result)
  {
    return 1
  }

  return [int]$result.ExitCode
}

function Test-PSCompletionsAvailable
{
  $command = @"
`$ErrorActionPreference = 'Stop'
Set-StrictMode -Off
Import-Module PSCompletions -Force -ErrorAction Stop

if (-not (Get-Command psc -ErrorAction SilentlyContinue)) {
  throw 'psc command is not available after importing PSCompletions.'
}
"@

  Invoke-CleanPwsh -Command $command | Out-Null
}

function Get-InstalledCompletionKeys
{
  $installed = @{}

  $rawItems = @(Invoke-PscJson -PscExpression "psc list")

  foreach ($entry in $rawItems)
  {
    if ($null -eq $entry)
    {
      continue
    }

    if (
      $entry.PSObject.Properties["Completion"] -and
      $entry.PSObject.Properties["Alias"]
    )
    {
      $completion = [string]$entry.Completion
      $alias = [string]$entry.Alias

      if (
        -not [string]::IsNullOrWhiteSpace($completion) -and
        -not [string]::IsNullOrWhiteSpace($alias)
      )
      {
        $installed["$completion|$alias"] = $true
        $installed[$completion] = $true
      }

      continue
    }

    $text = [string]$entry

    if ([string]::IsNullOrWhiteSpace($text))
    {
      continue
    }

    if ($text -match '^\s*Completion\s+Alias\s*$')
    {
      continue
    }

    if ($text -match '^\s*-+\s+-+\s*$')
    {
      continue
    }

    if ($text -match '^\s*(\S+)\s+(\S+)\s*$')
    {
      $completion = [string]$matches[1]
      $alias = [string]$matches[2]

      $installed["$completion|$alias"] = $true
      $installed[$completion] = $true
    }
  }

  return $installed
}

function Resolve-CompletionsFromManifest
{
  if ($Completions.Count -gt 0)
  {
    return @($Completions)
  }

  $repoRoot = Get-RepoRoot -StartPath $bootstrapRoot

  if ([string]::IsNullOrWhiteSpace($Manifest))
  {
    $Manifest = Join-Path $repoRoot "manifests\windows.packages.json"
  }

  $manifestPath = [System.IO.Path]::GetFullPath($Manifest)

  if (-not (Test-Path -LiteralPath $manifestPath))
  {
    throw "Windows package manifest not found: $manifestPath"
  }

  $manifestObject = Get-Content $manifestPath -Raw | ConvertFrom-Json -Depth 50

  if (-not $manifestObject.PSObject.Properties["powershellCompletions"])
  {
    return @()
  }

  return @($manifestObject.powershellCompletions)
}

function Normalize-CompletionItem
{
  param([object]$CompletionItem)

  $completion = [string](Get-PropertyValue -Object $CompletionItem -Name "completion" -Fallback "")
  $alias = [string](Get-PropertyValue -Object $CompletionItem -Name "alias" -Fallback $completion)

  if ([string]::IsNullOrWhiteSpace($completion))
  {
    return $null
  }

  if ([string]::IsNullOrWhiteSpace($alias))
  {
    $alias = $completion
  }

  return [pscustomobject]@{
    Completion = $completion
    Alias = $alias
  }
}

function Add-PSCompletion
{
  param(
    [Parameter(Mandatory = $true)]
    [object]$CompletionItem,

    [hashtable]$InstalledKeys
  )

  $completion = [string]$CompletionItem.Completion
  $alias = [string]$CompletionItem.Alias
  $exactKey = "$completion|$alias"

  if (-not $Force -and ($InstalledKeys.ContainsKey($exactKey) -or $InstalledKeys.ContainsKey($completion)))
  {
    Write-TaskOk "$completion already added"

    return [pscustomobject]@{
      Name = $completion
      Status = "skipped"
    }
  }

  if ($alias -ne $completion)
  {
    $exitCode = Invoke-PscAdd `
      -Completion $completion `
      -Alias $alias `
      -AllowFailure

    if ($exitCode -eq 0)
    {
      return [pscustomobject]@{
        Name = $completion
        Status = "added"
      }
    }

    Write-TaskWarn "psc add $completion $alias failed; retrying with psc add $completion"
  }

  Invoke-PscAdd -Completion $completion | Out-Null

  return [pscustomobject]@{
    Name = $completion
    Status = "added"
  }
}

# Resolve completion plan.

$completionItems = @(
  Resolve-CompletionsFromManifest |
    ForEach-Object { Normalize-CompletionItem -CompletionItem $_ } |
    Where-Object { $null -ne $_ } |
    Sort-Object Completion, Alias
)

if ($completionItems.Count -eq 0)
{
  Write-TaskWarn "No PowerShell completions declared."
  exit 0
}

# Verify PSCompletions in a clean process.

Test-PSCompletionsAvailable

# Add completions.

Write-TaskStep "Adding PowerShell Completions ($($completionItems.Count) declared)"

$installedKeys = Get-InstalledCompletionKeys
$results = @()
$failed = @()

foreach ($completionItem in $completionItems)
{
  try
  {
    $result = Add-PSCompletion `
      -CompletionItem $completionItem `
      -InstalledKeys $installedKeys

    $results += $result

    if ($result.Status -eq "added")
    {
      $installedKeys["$($completionItem.Completion)|$($completionItem.Alias)"] = $true
      $installedKeys[$completionItem.Completion] = $true
      Write-TaskOk "$($completionItem.Completion) added"
    }
  } catch
  {
    Write-TaskWarn "Failed to add $($completionItem.Completion): $($_.Exception.Message)"

    $failed += [pscustomobject]@{
      Name = [string]$completionItem.Completion
      Error = $_.Exception.Message
    }
  }
}

# Summary.

$addedCount = @($results | Where-Object { $_.Status -eq "added" }).Count
$skippedCount = @($results | Where-Object { $_.Status -eq "skipped" }).Count

Write-Host ""
Write-Host "─────────────────────────────────" -ForegroundColor DarkGray
Write-TaskOk "Added   : $addedCount"
Write-Host " · Skipped : $skippedCount (already present)" -ForegroundColor DarkGray

if ($failed.Count -gt 0)
{
  Write-Host ""
  Write-TaskWarn "Failed to add $($failed.Count) completion(s):"

  foreach ($item in $failed)
  {
    Write-TaskWarn " · $($item.Name): $($item.Error)"
  }

  exit 1
}
