param(
  [switch]$ElevatedChild,
  [string]$TargetUser,
  [string]$TargetProfilePath
)

$script:ChezmoiUacTaskName = "remove-bloat"

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
#   $XDG_RUNTIME_DIR\chezmoi\remove-bloat\

# 如果未设置 XDG_RUNTIME_DIR，则回退到：
#   $XDG_CACHE_HOME\chezmoi\tmp\remove-bloat\

# 如果未设置 XDG_CACHE_HOME，则最终回退到：
#   $HOME\.cache\chezmoi\tmp\remove-bloat\

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
  $taskNameLiteral = ConvertTo-PSLiteral -Value $script:ChezmoiUacTaskName

  $wrapper = @(
    '$ErrorActionPreference = "Stop"'
    '$taskName = ' + $taskNameLiteral
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
    '    Append-TextToFile -Path $childStderrPath -Text ($_ | Out-String)'
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
# --- [Remove common Windows preinstalled / consumer apps] ---
# ==================================================================================

# Keep Microsoft Store components because some winget packages use msstore.

$Packages = @(
  @{
    Comment = "Clipchamp：微软预装视频编辑器"
    Name    = "Clipchamp.Clipchamp"
  },
  @{
    Comment = "Cortana / 旧搜索相关组件（不同版本可能不同）"
    Name    = "Microsoft.549981C3F5F10"
  },
  @{
    Comment = "Bing News：新闻"
    Name    = "Microsoft.BingNews"
  },
  @{
    Comment = "Bing Weather：天气"
    Name    = "Microsoft.BingWeather"
  },
  @{
    Comment = "Gaming App：Xbox / 游戏入口"
    Name    = "Microsoft.GamingApp"
  },
  @{
    Comment = "Get Help：获取帮助"
    Name    = "Microsoft.GetHelp"
  },
  @{
    Comment = "Get Started：Windows 入门"
    Name    = "Microsoft.Getstarted"
  },
  @{
    Comment = "3D Viewer：3D 查看器"
    Name    = "Microsoft.Microsoft3DViewer"
  },
  @{
    Comment = "Office Hub：Office 推广入口"
    Name    = "Microsoft.MicrosoftOfficeHub"
  },
  @{
    Comment = "Solitaire Collection：纸牌合集"
    Name    = "Microsoft.MicrosoftSolitaireCollection"
  },
  @{
    Comment = "Mixed Reality Portal：混合现实门户"
    Name    = "Microsoft.MixedReality.Portal"
  },
  @{
    Comment = "Outlook for Windows：新版 Outlook"
    Name    = "Microsoft.OutlookForWindows"
  },
  @{
    Comment = "People：联系人"
    Name    = "Microsoft.People"
  },
  @{
    Comment = "Skype：Skype 客户端"
    Name    = "Microsoft.SkypeApp"
  },
  @{
    Comment = "Feedback Hub：反馈中心"
    Name    = "Microsoft.WindowsFeedbackHub"
  },
  @{
    Comment = "Maps：地图"
    Name    = "Microsoft.WindowsMaps"
  },
  @{
    Comment = "Xbox TCUI：Xbox 界面组件"
    Name    = "Microsoft.Xbox.TCUI"
  },
  @{
    Comment = "Xbox App：Xbox 主应用"
    Name    = "Microsoft.XboxApp"
  },
  @{
    Comment = "Xbox Game Overlay：游戏悬浮层"
    Name    = "Microsoft.XboxGameOverlay"
  },
  @{
    Comment = "Xbox Gaming Overlay：游戏覆盖层"
    Name    = "Microsoft.XboxGamingOverlay"
  },
  @{
    Comment = "Xbox Identity Provider：Xbox 身份组件"
    Name    = "Microsoft.XboxIdentityProvider"
  },
  @{
    Comment = "Xbox Speech To Text Overlay：Xbox 语音转文字组件"
    Name    = "Microsoft.XboxSpeechToTextOverlay"
  },
  @{
    Comment = "Your Phone / Phone Link：手机连接"
    Name    = "Microsoft.YourPhone"
  },
  @{
    Comment = "Zune Music：Groove 音乐"
    Name    = "Microsoft.ZuneMusic"
  },
  @{
    Comment = "Zune Video：Movies & TV"
    Name    = "Microsoft.ZuneVideo"
  }
)

$JunkRegex = "xbox|phone|skype|spotify|groove|solitaire|zune|mixedreality|bingweather|3dviewer|clipchamp|officehub|outlookforwindows"

$Summary = [ordered]@{
  CurrentUserRemoved = 0
  CurrentUserSkipped = 0
  CurrentUserFailed  = 0
  AllUsersRemoved    = 0
  AllUsersSkipped    = 0
  AllUsersFailed     = 0
  RegexRemoved       = 0
  RegexSkipped       = 0
  RegexFailed        = 0
  ProvisionedRemoved = 0
  ProvisionedSkipped = 0
  ProvisionedFailed  = 0
}

function Add-Summary
{
  param(
    [Parameter(Mandatory)]
    [string]$Key
  )

  $Summary[$Key] = [int]$Summary[$Key] + 1
}

function Write-Info
{
  param(
    [Parameter(Mandatory)]
    [string]$Text
  )

  Write-Host $Text -ForegroundColor Cyan
}

function Write-Ok
{
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Text
  )

  Write-Host ("[OK] {0} - {1}" -f $Name, $Text) -ForegroundColor Green
}

function Write-Skip
{
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Text
  )

  Write-Host ("[SKIP] {0} - {1}" -f $Name, $Text) -ForegroundColor DarkYellow
}

function Write-Fail
{
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Text
  )

  Write-Host ("[FAIL] {0} - {1}" -f $Name, $Text) -ForegroundColor Red
}

function Test-RemovableAppxPackage
{
  param(
    [Parameter(Mandatory)]
    $Package
  )

  if ($null -eq $Package.PSObject.Properties["NonRemovable"])
  {
    return $true
  }

  return -not [bool]$Package.NonRemovable
}

function Remove-CurrentUserPackage
{
  param(
    [Parameter(Mandatory)]
    [string]$Name
  )

  try
  {
    $matchedPackages = @(Get-AppxPackage -Name $Name -ErrorAction SilentlyContinue)

    if ($matchedPackages.Count -eq 0)
    {
      Add-Summary -Key "CurrentUserSkipped"
      Write-Skip $Name "当前用户未安装"
      return
    }

    foreach ($pkg in $matchedPackages)
    {
      try
      {
        Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
        Add-Summary -Key "CurrentUserRemoved"
        Write-Ok $Name "已从当前用户移除"
      } catch
      {
        Add-Summary -Key "CurrentUserFailed"
        Write-Fail $Name ("当前用户移除失败: {0}" -f $_.Exception.Message)
      }
    }
  } catch
  {
    Add-Summary -Key "CurrentUserFailed"
    Write-Fail $Name ("当前用户查询失败: {0}" -f $_.Exception.Message)
  }
}

function Remove-AllUsersPackage
{
  param(
    [Parameter(Mandatory)]
    [string]$Name
  )

  try
  {
    $matchedPackages = @(Get-AppxPackage -AllUsers -Name $Name -ErrorAction SilentlyContinue)

    if ($matchedPackages.Count -eq 0)
    {
      Add-Summary -Key "AllUsersSkipped"
      Write-Skip $Name "所有用户范围未找到"
      return
    }

    foreach ($pkg in $matchedPackages)
    {
      try
      {
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
        Add-Summary -Key "AllUsersRemoved"
        Write-Ok $Name "已从所有用户移除"
      } catch
      {
        Add-Summary -Key "AllUsersFailed"
        Write-Fail $Name ("所有用户移除失败: {0}" -f $_.Exception.Message)
      }
    }
  } catch
  {
    Add-Summary -Key "AllUsersFailed"
    Write-Fail $Name ("所有用户查询失败: {0}" -f $_.Exception.Message)
  }
}

function Remove-RegexPackages
{
  param(
    [Parameter(Mandatory)]
    [string]$Regex
  )

  try
  {
    $allPackages = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue)
    $matchedPackages = @()

    foreach ($pkg in $allPackages)
    {
      if ($pkg.Name -match $Regex -and (Test-RemovableAppxPackage -Package $pkg))
      {
        $matchedPackages += $pkg
      }
    }

    if ($matchedPackages.Count -eq 0)
    {
      Add-Summary -Key "RegexSkipped"
      Write-Skip $Regex "没有匹配到额外可移除应用"
      return
    }

    foreach ($pkg in $matchedPackages)
    {
      try
      {
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
        Add-Summary -Key "RegexRemoved"
        Write-Ok $pkg.Name "关键字匹配移除成功"
      } catch
      {
        Add-Summary -Key "RegexFailed"
        Write-Fail $pkg.Name ("关键字匹配移除失败: {0}" -f $_.Exception.Message)
      }
    }
  } catch
  {
    Add-Summary -Key "RegexFailed"
    Write-Fail $Regex ("关键字匹配查询失败: {0}" -f $_.Exception.Message)
  }
}

function Remove-ProvisionedPackages
{
  param(
    [Parameter(Mandatory)]
    [string]$Regex
  )

  try
  {
    $allProvisionedPackages = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue)
    $matchedProvisionedPackages = @()

    foreach ($pkg in $allProvisionedPackages)
    {
      if ($pkg.DisplayName -match $Regex)
      {
        $matchedProvisionedPackages += $pkg
      }
    }

    if ($matchedProvisionedPackages.Count -eq 0)
    {
      Add-Summary -Key "ProvisionedSkipped"
      Write-Skip $Regex "没有匹配到 provisioned packages"
      return
    }

    $index = 0

    foreach ($pkg in $matchedProvisionedPackages)
    {
      $index++
      Write-Info ("正在处理 provisioned package [{0}/{1}] {2}" -f $index, $matchedProvisionedPackages.Count, $pkg.DisplayName)

      try
      {
        $null = Remove-AppxProvisionedPackage `
          -Online `
          -AllUsers `
          -PackageName $pkg.PackageName `
          -ErrorAction Stop

        Add-Summary -Key "ProvisionedRemoved"
        Write-Ok $pkg.DisplayName "provisioned package 已移除"
      } catch
      {
        Add-Summary -Key "ProvisionedFailed"
        Write-Fail $pkg.DisplayName ("provisioned package 移除失败: {0}" -f $_.Exception.Message)
      }
    }
  } catch
  {
    Add-Summary -Key "ProvisionedFailed"
    Write-Fail $Regex ("provisioned package 查询失败: {0}" -f $_.Exception.Message)
  }
}

Write-Host ""
Write-Host "Removing selected built-in apps..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $Packages)
{
  Write-Host ("# {0}" -f $entry.Comment) -ForegroundColor DarkGray

  Remove-CurrentUserPackage -Name $entry.Name
  Remove-AllUsersPackage -Name $entry.Name

  Write-Host ""
}

Write-Host "# 按关键字补充清理剩余的消费类 / 预装类应用" -ForegroundColor DarkGray
Remove-RegexPackages -Regex $JunkRegex

Write-Host ""
Write-Host "# 清理 provisioned packages，避免新用户再次自动带回这些应用" -ForegroundColor DarkGray
Remove-ProvisionedPackages -Regex $JunkRegex

Write-Host ""
Write-Host "Summary" -ForegroundColor Cyan

foreach ($entry in $Summary.GetEnumerator())
{
  Write-Host (" {0} = {1}" -f $entry.Key, $entry.Value)
}
