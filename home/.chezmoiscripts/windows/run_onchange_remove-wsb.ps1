param(
  [switch]$ElevatedChild,
  [string]$TargetUser,
  [string]$TargetProfilePath
)

$script:ChezmoiUacTaskName = "remove-wsb"

$ErrorActionPreference = "Stop"

# ==================================================================================
# --- [UAC / XDG Temp Bootstrap] ---
# ==================================================================================

# 此脚本需要管理员权限。

# 普通非管理员 chezmoi apply 时：

#   parent 当前终端
#     -> UAC wrapper 管理员进程
#         -> child stdout/stderr 写入临时文件
#     -> wrapper 结束
#     -> parent 读取临时 stdout/stderr
#     -> parent 打印到当前终端
#     -> parent 清理临时文件

# 临时 wrapper / child 文件路径：
#   $XDG_RUNTIME_DIR\chezmoi\remove-wsb\

# 如果未设置 XDG_RUNTIME_DIR，则回退到：
#   $XDG_CACHE_HOME\chezmoi\tmp\remove-wsb\

# 如果未设置 XDG_CACHE_HOME，则最终回退到：
#   $HOME\.cache\chezmoi\tmp\remove-wsb\

# ==================================================================================

function Test-IsAdministrator
{
  $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [System.Security.Principal.WindowsPrincipal]::new($identity)

  return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-IsAbsolutePath
{
  param(
    [string]$Path
  )

  if ([string]::IsNullOrWhiteSpace($Path))
  {
    return $false
  }

  return [System.IO.Path]::IsPathRooted($Path)
}

function Get-TargetProfilePath
{
  if (-not [string]::IsNullOrWhiteSpace($TargetProfilePath))
  {
    return $TargetProfilePath
  }

  if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE))
  {
    return $env:USERPROFILE
  }

  return $HOME
}

function Get-XdgCacheHome
{
  param(
    [Parameter(Mandatory)]
    [string]$ProfilePath
  )

  if (Test-IsAbsolutePath -Path $env:XDG_CACHE_HOME)
  {
    return $env:XDG_CACHE_HOME
  }

  return [System.IO.Path]::Combine($ProfilePath, ".cache")
}

function Get-ChezmoiTempRoot
{
  $profilePath = Get-TargetProfilePath

  if (Test-IsAbsolutePath -Path $env:XDG_RUNTIME_DIR)
  {
    $root = [System.IO.Path]::Combine($env:XDG_RUNTIME_DIR, "chezmoi", $script:ChezmoiUacTaskName)
  } else
  {
    $cacheHome = Get-XdgCacheHome -ProfilePath $profilePath
    $root = [System.IO.Path]::Combine($cacheHome, "chezmoi", "tmp", $script:ChezmoiUacTaskName)
  }

  if (-not (Test-Path -LiteralPath $root -PathType Container))
  {
    $null = New-Item -Path $root -ItemType Directory -Force
  }

  return $root
}

function ConvertTo-PSLiteral
{
  param(
    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Value
  )

  return "'" + $Value.Replace("'", "''") + "'"
}

function Remove-GeneratedFile
{
  param(
    [string[]]$Path
  )

  foreach ($item in $Path)
  {
    if ([string]::IsNullOrWhiteSpace($item))
    {
      continue
    }

    Remove-Item -LiteralPath $item -Force -ErrorAction SilentlyContinue
  }
}

function Remove-OldGeneratedFiles
{
  param(
    [Parameter(Mandatory)]
    [string]$Root,

    [int]$OlderThanDays = 7
  )

  if (-not (Test-Path -LiteralPath $Root -PathType Container))
  {
    return
  }

  $cutoff = (Get-Date).AddDays(-$OlderThanDays)
  $files = Get-ChildItem -LiteralPath $Root -Filter "chezmoi-$script:ChezmoiUacTaskName-*" -File -ErrorAction SilentlyContinue

  foreach ($file in $files)
  {
    if ($file.LastWriteTime -lt $cutoff)
    {
      Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
    }
  }
}

function Read-TextFile
{
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf))
  {
    return ""
  }

  $reader = [System.IO.StreamReader]::new($Path, $true)

  try
  {
    return $reader.ReadToEnd()
  } finally
  {
    $reader.Dispose()
  }
}

function Write-CapturedOutputToTerminal
{
  param(
    [Parameter(Mandatory)]
    [string]$StdoutPath,

    [Parameter(Mandatory)]
    [string]$StderrPath
  )

  $stdoutText = Read-TextFile -Path $StdoutPath
  $stderrText = Read-TextFile -Path $StderrPath

  if (-not [string]::IsNullOrEmpty($stdoutText))
  {
    [Console]::Out.Write($stdoutText)
  }

  if (-not [string]::IsNullOrEmpty($stderrText))
  {
    [Console]::Error.Write($stderrText)
  }
}

function Invoke-SelfElevatedIfNeeded
{
  if (Test-IsAdministrator)
  {
    return
  }

  $targetUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  $targetProfile = Get-TargetProfilePath
  $tempRoot = Get-ChezmoiTempRoot

  Remove-OldGeneratedFiles -Root $tempRoot -OlderThanDays 7

  Write-Warning "当前不是管理员权限，正在请求 UAC 提权以执行 $script:ChezmoiUacTaskName..."

  if ([string]::IsNullOrWhiteSpace($PSCommandPath) -or -not (Test-Path -LiteralPath $PSCommandPath -PathType Leaf))
  {
    Write-Error "无法定位当前脚本路径，无法执行 UAC 提权。"
    exit 1
  }

  $id = [guid]::NewGuid().ToString("N")
  $wrapperPath = [System.IO.Path]::Combine($tempRoot, "chezmoi-$script:ChezmoiUacTaskName-elevated-$id.ps1")
  $childScriptPath = [System.IO.Path]::Combine($tempRoot, "chezmoi-$script:ChezmoiUacTaskName-child-$id.ps1")
  $childStdoutPath = [System.IO.Path]::Combine($tempRoot, "chezmoi-$script:ChezmoiUacTaskName-child-$id.stdout.log")
  $childStderrPath = [System.IO.Path]::Combine($tempRoot, "chezmoi-$script:ChezmoiUacTaskName-child-$id.stderr.log")

  # chezmoi 生成的临时脚本可能是 UTF-8 without BOM。
  # Windows PowerShell 5.1 重新读取时可能按 ANSI 解析，从而把中文字符串/注释读坏。
  # 因此复制一份 UTF-8 BOM 版本给 elevated child 执行。
  $scriptText = [System.IO.File]::ReadAllText($PSCommandPath, [System.Text.Encoding]::UTF8)
  $utf8Bom = [System.Text.UTF8Encoding]::new($true)
  [System.IO.File]::WriteAllText($childScriptPath, $scriptText, $utf8Bom)

  $scriptPathLiteral = ConvertTo-PSLiteral -Value $childScriptPath
  $targetUserLiteral = ConvertTo-PSLiteral -Value $targetUser
  $targetProfileLiteral = ConvertTo-PSLiteral -Value $targetProfile
  $childStdoutLiteral = ConvertTo-PSLiteral -Value $childStdoutPath
  $childStderrLiteral = ConvertTo-PSLiteral -Value $childStderrPath

  $wrapper = @(
    '$ErrorActionPreference = "Stop"'
    '$scriptPath = ' + $scriptPathLiteral
    '$targetUser = ' + $targetUserLiteral
    '$targetProfile = ' + $targetProfileLiteral
    '$childStdoutPath = ' + $childStdoutLiteral
    '$childStderrPath = ' + $childStderrLiteral
    '$script:ExitCode = 1'
    ''
    'function Append-TextToFile {'
    '    param('
    '        [Parameter(Mandatory)]'
    '        [string]$Path,'
    '        [Parameter(Mandatory)]'
    '        [string]$Text'
    '    )'
    ''
    '    Add-Content -LiteralPath $Path -Value $Text -Encoding UTF8'
    '}'
    ''
    'try {'
    '    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {'
    '        throw "script path does not exist: $scriptPath"'
    '    }'
    ''
    '    $childArgs = @('
    '        "-NoProfile",'
    '        "-ExecutionPolicy", "Bypass",'
    '        "-File", $scriptPath,'
    '        "-ElevatedChild",'
    '        "-TargetUser", $targetUser,'
    '        "-TargetProfilePath", $targetProfile'
    '    )'
    ''
    '    & powershell.exe @childArgs > $childStdoutPath 2> $childStderrPath'
    '    $exitCode = $LASTEXITCODE'
    ''
    '    if ($null -eq $exitCode) {'
    '        $exitCode = 0'
    '    }'
    ''
    '    $script:ExitCode = $exitCode'
    '} catch {'
    '    Append-TextToFile -Path $childStderrPath -Text "WRAPPER ERROR: $($_.Exception.Message)"'
    '    Append-TextToFile -Path $childStderrPath -Text $_.ToString()'
    '    $script:ExitCode = 1'
    '}'
    ''
    'exit $script:ExitCode'
  )

  [System.IO.File]::WriteAllLines($wrapperPath, $wrapper, $utf8Bom)

  $script:ParentExitCode = 1

  try
  {
    $parentStartParams = @{
      FilePath = "powershell.exe"
      ArgumentList = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $wrapperPath
      )
      Verb = "RunAs"
      Wait = $true
      PassThru = $true
    }

    $process = Start-Process @parentStartParams

    Write-CapturedOutputToTerminal -StdoutPath $childStdoutPath -StderrPath $childStderrPath

    if ($null -ne $process -and $process.ExitCode -ne 0)
    {
      $script:ParentExitCode = $process.ExitCode
    } else
    {
      $script:ParentExitCode = 0
    }
  } catch
  {
    Write-Error "UAC 提权被取消或失败，$script:ChezmoiUacTaskName 执行失败：$($_.Exception.Message)"
    $script:ParentExitCode = 1
  } finally
  {
    Remove-GeneratedFile -Path @(
      $wrapperPath,
      $childScriptPath,
      $childStdoutPath,
      $childStderrPath
    )
  }

  exit $script:ParentExitCode
}

Invoke-SelfElevatedIfNeeded

# ==================================================================================
# --- [Registry policy cleanup / configuration] ---
# ==================================================================================

# 在这里声明需要写入的注册表策略。

# 格式:
# @{
#     Comment = "说明"
#     Path    = "注册表路径"
#     Name    = "属性名"
#     Type    = "DWord"
#     Value   = 0
# }

# 添加新的策略时，只需要继续往 $RegistryValues 里加 hashtable，
# 不需要修改后面的执行逻辑。
# ==================================================================================

$RegistryValues = @(
  @{
    Comment = "Disable Windows Search Box dynamic content"
    Path    = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    Name    = "EnableDynamicContentInWSB"
    Type    = "DWord"
    Value   = 0
  }

  # 示例:
  # ,@{
  #     Comment = "Disable something else"
  #     Path    = "HKLM:\SOFTWARE\Policies\Vendor\Product"
  #     Name    = "SomePolicy"
  #     Type    = "DWord"
  #     Value   = 0
  # }
)

function Write-Step
{
  param(
    [Parameter(Mandatory)]
    [string]$Message
  )

  [Console]::Out.WriteLine($Message)
}

function Write-StepError
{
  param(
    [Parameter(Mandatory)]
    [string]$Message
  )

  [Console]::Error.WriteLine($Message)
}

function Set-RegistryValue
{
  param(
    [Parameter(Mandatory)]
    [hashtable]$Entry
  )

  foreach ($key in @("Path", "Name", "Type", "Value"))
  {
    if (-not $Entry.ContainsKey($key))
    {
      throw "Registry entry is missing required key: $key"
    }
  }

  $comment = if ($Entry.ContainsKey("Comment"))
  { [string]$Entry.Comment 
  } else
  { [string]$Entry.Name 
  }
  $path = [string]$Entry.Path
  $name = [string]$Entry.Name
  $type = [string]$Entry.Type
  $value = $Entry.Value

  Write-Step ("# {0}" -f $comment)

  if (-not (Test-Path -LiteralPath $path))
  {
    Write-Step ("create key: {0}" -f $path)
    $null = New-Item -Path $path -Force
  }

  $current = Get-ItemProperty -LiteralPath $path -Name $name -ErrorAction SilentlyContinue

  if ($null -ne $current -and $current.PSObject.Properties.Name -contains $name)
  {
    $currentValue = $current.$name

    if ($currentValue -eq $value)
    {
      Write-Step ("skip: {0}\{1} already equals {2}" -f $path, $name, $value)
      return
    }
  }

  $null = New-ItemProperty `
    -Path $path `
    -Name $name `
    -PropertyType $type `
    -Value $value `
    -Force

  Write-Step ("set: {0}\{1} = {2} ({3})" -f $path, $name, $value, $type)
}

$failed = 0

foreach ($entry in $RegistryValues)
{
  try
  {
    Set-RegistryValue -Entry $entry
  } catch
  {
    $failed++
    Write-StepError ("failed: {0}" -f $_.Exception.Message)
  }
}

if ($failed -gt 0)
{
  throw ("{0} registry operation(s) failed." -f $failed)
}
