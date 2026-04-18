param(
  [Parameter(Mandatory = $true)]
  $Context
)

$ErrorActionPreference = "Stop"

Write-Step "Initializing XDG Environment"

# 行为：
#   1. 写入 User 级环境变量
#   2. 同步到当前会话
#   3. 创建对应目录/文件

# 幂等性：
#   - 已存在的目录或文件不会重复创建
#   - 已存在的变量会被覆盖为当前约定值，确保环境一致

$xdgMap = Get-XdgEnvironmentMap

if ($null -eq $xdgMap -or $xdgMap.Count -eq 0)
{
  throw "Get-XdgEnvironmentMap returned no values."
}

foreach ($key in $xdgMap.Keys)
{
  $entry = $xdgMap[$key]

  if ($null -eq $entry)
  {
    throw "Resolved XDG entry for '$key' is null."
  }

  $value = [string]$entry.Path
  $type  = [string]$entry.Type

  if ([string]::IsNullOrWhiteSpace($value))
  {
    throw "Resolved XDG path for '$key' is empty."
  }

  if ([string]::IsNullOrWhiteSpace($type))
  {
    throw "Resolved XDG type for '$key' is empty."
  }

  $previousUserValue = [System.Environment]::GetEnvironmentVariable($key, "User")

  Set-UserEnvironmentVariable -Name $key -Value $value

  if ($previousUserValue -ne $value)
  {
    Write-Host "  -> Set $key = $value" -ForegroundColor Green
  } else
  {
    Write-Host "  -> $key already set to $value" -ForegroundColor DarkGray
  }

  if (-not (Test-Path -LiteralPath $value))
  {
    New-PathIfMissing -Path $value -PathType $type

    if ($type -eq "Directory")
    {
      Write-Host "  -> Created directory: $value" -ForegroundColor Green
    } else
    {
      Write-Host "  -> Created file: $value" -ForegroundColor Green
    }
  } else
  {
    if ($type -eq "Directory")
    {
      Write-Host "  -> Directory exists: $value" -ForegroundColor DarkGray
    } else
    {
      Write-Host "  -> File exists: $value" -ForegroundColor DarkGray
    }
  }
}

# 某些后续步骤（如 mise / chezmoi / yazi 相关路径）会依赖这些变量，
# 所以这里再统一刷新一次当前会话 PATH/环境感知。
Update-PathEnvironment

Write-OK "XDG environment initialized for current user"
