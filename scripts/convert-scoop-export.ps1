# scripts/convert-scoop-export.ps1
# 功能：读取 scoop export 结果，自动更新 windows.packages.json 中的 Scoop 配置。
# 用法：.\scripts\convert-scoop-export.ps1

param(
    [string]$TargetFile = "manifests/windows.packages.json"
)

$ErrorActionPreference = "Stop"

# ─── 可选安装列表 ─────────────────────────────────────────────
# 这里的 App 将会被移动到 optional.scoopTools 中，不会默认安装。
$OptionalApps = @(
    "texlive-full"
    # "libreoffice",
    # "qbittorrent-enhanced"
    # 在此处添加更多...
)
# ─────────────────────────────────────────────────────────────────────────────

# 1. 检查 Scoop 是否可用
if (-not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
    Write-Error "Scoop is not installed or not in PATH."
    exit 1
}

$targetPath = Join-Path $PSScriptRoot "..\$TargetFile"

Write-Host "Running 'scoop export'..." -ForegroundColor Cyan
try {
    # 直接捕获 Scoop 输出流并转换为 JSON 对象
    $jsonRaw = scoop export | Out-String
    $scoopData = $jsonRaw | ConvertFrom-Json
} catch {
    Write-Error "Failed to export scoop manifest: $_"
    exit 1
}

# 2. 准备新的 Scoop 数据结构
$newBuckets = @()
$newTools = @()
$newOptionalTools = @()

# 处理 Buckets
foreach ($bucket in $scoopData.buckets) {
    if ($bucket.Name -eq "main") { continue } # 跳过 main bucket
    $b = [PSCustomObject]@{ name = $bucket.Name }
    if ($bucket.Source) { $b | Add-Member -NotePropertyName "url" -NotePropertyValue $bucket.Source }
    $newBuckets += $b
}

# 处理 Apps
foreach ($app in $scoopData.apps) {
    $item = [PSCustomObject]@{
        name   = $app.Name
        bucket = $app.Source
    }

    if ($OptionalApps -contains $app.Name) {
        $newOptionalTools += $item
    } else {
        $newTools += $item
    }
}

# 3. 读取目标 manifest (或创建新对象)
if (Test-Path $targetPath) {
    Write-Host "Updating existing manifest: $targetPath" -ForegroundColor Cyan
    $manifest = Get-Content $targetPath -Raw | ConvertFrom-Json
} else {
    Write-Host "Creating new manifest: $targetPath" -ForegroundColor Yellow
    $manifest = [PSCustomObject]@{
        scoopBuckets      = @()
        scoopTools        = @()
        optional          = [PSCustomObject]@{ scoopBuckets = @(); scoopTools = @() }
        wingetPackages    = @()
        powershellModules = @()
        fonts             = @()
    }
}

# 4. 合并数据 (覆盖 Scoop 相关字段，保留其他)
$manifest.scoopBuckets = $newBuckets
$manifest.scoopTools   = $newTools

# 确保 optional 对象存在
if (-not $manifest.PSObject.Properties["optional"]) {
    $manifest | Add-Member -NotePropertyName "optional" -NotePropertyValue ([PSCustomObject]@{ scoopBuckets = @(); scoopTools = @() })
}
# 确保 optional.scoopTools 存在
if (-not $manifest.optional.PSObject.Properties["scoopTools"]) {
    $manifest.optional | Add-Member -NotePropertyName "scoopTools" -NotePropertyValue @()
}

# 更新 Optional Tools
$manifest.optional.scoopTools = $newOptionalTools

# 5. 写回文件
$jsonOptions = @{
    Depth = 10
    Compress = $false
}
# 确保文件使用 UTF8 编码
$jsonContent = $manifest | ConvertTo-Json @jsonOptions
Set-Content -Path $targetPath -Value $jsonContent -Encoding UTF8

# 6. 总结
Write-Host "`nSuccessfully updated $TargetFile" -ForegroundColor Green
Write-Host "  Buckets          : $($newBuckets.Count)"
Write-Host "  Core Apps        : $($newTools.Count)"
Write-Host "  Optional Apps    : $($newOptionalTools.Count)"
Write-Host "  Preserved fields : wingetPackages, powershellModules, etc." -ForegroundColor Gray
