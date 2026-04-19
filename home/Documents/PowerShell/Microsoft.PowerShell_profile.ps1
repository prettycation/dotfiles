$ProfileRoot = Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.d'

$Always = @(
  '00-core.ps1'
  '10-theme-and-helpers.ps1'
  '20-env.ps1'
  '30-functions.ps1'
  '40-aliases.ps1'
  '70-secrets.ps1'
)

$Interactive = @(
  '50-interactive.ps1'
)

$Startup = @(
  '60-startup-banner.ps1'
)

foreach ($name in $Always)
{
  $path = Join-Path $ProfileRoot $name
  if (Test-Path -LiteralPath $path)
  {
    . $path
  }
}

if ($EnableInteractiveProfile)
{
  foreach ($name in $Interactive)
  {
    $path = Join-Path $ProfileRoot $name
    if (Test-Path -LiteralPath $path)
    {
      . $path
    }
  }
}

if ($EnableStartupBanner)
{
  foreach ($name in $Startup)
  {
    $path = Join-Path $ProfileRoot $name
    if (Test-Path -LiteralPath $path)
    {
      . $path
    }
  }
}
