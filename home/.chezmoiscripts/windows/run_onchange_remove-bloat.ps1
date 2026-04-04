# Remove common Windows preinstalled / consumer apps.
# Keep Microsoft Store components because some winget packages use msstore.

$ErrorActionPreference = "Stop"

$Packages = @(
  @{
    Comment = "Clipchamp：微软预装视频编辑器"
    Name    = "Clipchamp.Clipchamp"
  }
  @{
    Comment = "Cortana / 旧搜索相关组件（不同版本可能不同）"
    Name    = "Microsoft.549981C3F5F10"
  }
  @{
    Comment = "Bing News：新闻"
    Name    = "Microsoft.BingNews"
  }
  @{
    Comment = "Bing Weather：天气"
    Name    = "Microsoft.BingWeather"
  }
  @{
    Comment = "Gaming App：Xbox / 游戏入口"
    Name    = "Microsoft.GamingApp"
  }
  @{
    Comment = "Get Help：获取帮助"
    Name    = "Microsoft.GetHelp"
  }
  @{
    Comment = "Get Started：Windows 入门"
    Name    = "Microsoft.Getstarted"
  }
  @{
    Comment = "3D Viewer：3D 查看器"
    Name    = "Microsoft.Microsoft3DViewer"
  }
  @{
    Comment = "Office Hub：Office 推广入口"
    Name    = "Microsoft.MicrosoftOfficeHub"
  }
  @{
    Comment = "Solitaire Collection：纸牌合集"
    Name    = "Microsoft.MicrosoftSolitaireCollection"
  }
  @{
    Comment = "Mixed Reality Portal：混合现实门户"
    Name    = "Microsoft.MixedReality.Portal"
  }
  @{
    Comment = "Outlook for Windows：新版 Outlook"
    Name    = "Microsoft.OutlookForWindows"
  }
  @{
    Comment = "People：联系人"
    Name    = "Microsoft.People"
  }
  @{
    Comment = "Skype：Skype 客户端"
    Name    = "Microsoft.SkypeApp"
  }
  @{
    Comment = "Feedback Hub：反馈中心"
    Name    = "Microsoft.WindowsFeedbackHub"
  }
  @{
    Comment = "Maps：地图"
    Name    = "Microsoft.WindowsMaps"
  }
  @{
    Comment = "Xbox TCUI：Xbox 界面组件"
    Name    = "Microsoft.Xbox.TCUI"
  }
  @{
    Comment = "Xbox App：Xbox 主应用"
    Name    = "Microsoft.XboxApp"
  }
  @{
    Comment = "Xbox Game Overlay：游戏悬浮层"
    Name    = "Microsoft.XboxGameOverlay"
  }
  @{
    Comment = "Xbox Gaming Overlay：游戏覆盖层"
    Name    = "Microsoft.XboxGamingOverlay"
  }
  @{
    Comment = "Xbox Identity Provider：Xbox 身份组件"
    Name    = "Microsoft.XboxIdentityProvider"
  }
  @{
    Comment = "Xbox Speech To Text Overlay：Xbox 语音转文字组件"
    Name    = "Microsoft.XboxSpeechToTextOverlay"
  }
  @{
    Comment = "Your Phone / Phone Link：手机连接"
    Name    = "Microsoft.YourPhone"
  }
  @{
    Comment = "Zune Music：Groove 音乐"
    Name    = "Microsoft.ZuneMusic"
  }
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

function Write-Info($Text) {
  Write-Host $Text -ForegroundColor Cyan
}

function Write-Ok($Name, $Text) {
  Write-Host ("[OK]   {0} - {1}" -f $Name, $Text) -ForegroundColor Green
}

function Write-Skip($Name, $Text) {
  Write-Host ("[SKIP] {0} - {1}" -f $Name, $Text) -ForegroundColor DarkYellow
}

function Write-Fail($Name, $Text) {
  Write-Host ("[FAIL] {0} - {1}" -f $Name, $Text) -ForegroundColor Red
}

function Remove-CurrentUserPackage([string]$Name) {
  try {
    $matches = @(Get-AppxPackage -Name $Name -ErrorAction SilentlyContinue)
    if ($matches.Count -eq 0) {
      $Summary.CurrentUserSkipped++
      Write-Skip $Name "当前用户未安装"
      return
    }

    foreach ($pkg in $matches) {
      try {
        Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
        $Summary.CurrentUserRemoved++
        Write-Ok $Name "已从当前用户移除"
      }
      catch {
        $Summary.CurrentUserFailed++
        Write-Fail $Name ("当前用户移除失败: {0}" -f $_.Exception.Message)
      }
    }
  }
  catch {
    $Summary.CurrentUserFailed++
    Write-Fail $Name ("当前用户查询失败: {0}" -f $_.Exception.Message)
  }
}

function Remove-AllUsersPackage([string]$Name) {
  try {
    $matches = @(Get-AppxPackage -AllUsers -Name $Name -ErrorAction SilentlyContinue)
    if ($matches.Count -eq 0) {
      $Summary.AllUsersSkipped++
      Write-Skip $Name "所有用户范围未找到"
      return
    }

    foreach ($pkg in $matches) {
      try {
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
        $Summary.AllUsersRemoved++
        Write-Ok $Name "已从所有用户移除"
      }
      catch {
        $Summary.AllUsersFailed++
        Write-Fail $Name ("所有用户移除失败: {0}" -f $_.Exception.Message)
      }
    }
  }
  catch {
    $Summary.AllUsersFailed++
    Write-Fail $Name ("所有用户查询失败: {0}" -f $_.Exception.Message)
  }
}

function Remove-RegexPackages([string]$Regex) {
  try {
    $matches = @(Get-AppxPackage -AllUsers | Where-Object { $_.Name -match $Regex } | Where-Object NonRemovable -eq $false)
    if ($matches.Count -eq 0) {
      $Summary.RegexSkipped++
      Write-Skip $Regex "没有匹配到额外可移除应用"
      return
    }

    foreach ($pkg in $matches) {
      try {
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
        $Summary.RegexRemoved++
        Write-Ok $pkg.Name "关键字匹配移除成功"
      }
      catch {
        $Summary.RegexFailed++
        Write-Fail $pkg.Name ("关键字匹配移除失败: {0}" -f $_.Exception.Message)
      }
    }
  }
  catch {
    $Summary.RegexFailed++
    Write-Fail $Regex ("关键字匹配查询失败: {0}" -f $_.Exception.Message)
  }
}

function Remove-ProvisionedPackages([string]$Regex) {
  try {
    $matches = @(Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -match $Regex })
    if ($matches.Count -eq 0) {
      $Summary.ProvisionedSkipped++
      Write-Skip $Regex "没有匹配到 provisioned packages"
      return
    }

    $index = 0
    foreach ($pkg in $matches) {
      $index++
      Write-Info ("正在处理 provisioned package [{0}/{1}] {2}" -f $index, $matches.Count, $pkg.DisplayName)
      try {
        Remove-AppxProvisionedPackage -Online -AllUsers -PackageName $pkg.PackageName -ErrorAction Stop | Out-Null
        $Summary.ProvisionedRemoved++
        Write-Ok $pkg.DisplayName "provisioned package 已移除"
      }
      catch {
        $Summary.ProvisionedFailed++
        Write-Fail $pkg.DisplayName ("provisioned package 移除失败: {0}" -f $_.Exception.Message)
      }
    }
  }
  catch {
    $Summary.ProvisionedFailed++
    Write-Fail $Regex ("provisioned package 查询失败: {0}" -f $_.Exception.Message)
  }
}

Write-Host ""
Write-Host "Removing selected built-in apps..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $Packages) {
  Write-Host ("# {0}" -f $entry.Comment) -ForegroundColor DarkGray
  Remove-CurrentUserPackage $entry.Name
  Remove-AllUsersPackage $entry.Name
  Write-Host ""
}

Write-Host "# 按关键字补充清理剩余的消费类 / 预装类应用" -ForegroundColor DarkGray
Remove-RegexPackages $JunkRegex
Write-Host ""

Write-Host "# 清理 provisioned packages，避免新用户再次自动带回这些应用" -ForegroundColor DarkGray
Remove-ProvisionedPackages $JunkRegex
Write-Host ""

Write-Host "Summary" -ForegroundColor Cyan
$Summary.GetEnumerator() | ForEach-Object {
  Write-Host ("  {0} = {1}" -f $_.Key, $_.Value)
}
