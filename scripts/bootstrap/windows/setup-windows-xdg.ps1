# ==============================================================================
# Windows XDG Base Directory Setup Script
# ==============================================================================

Write-Host "Configuring pure XDG Base Directory environment variables..." -ForegroundColor Cyan

$userProfile = $env:USERPROFILE

# XDG 规范变量
$xdgVars = @{
    "XDG_CONFIG_HOME" = "$userProfile\.config"
    "XDG_DATA_HOME"   = "$userProfile\.local\share"
    "XDG_STATE_HOME"  = "$userProfile\.local\state"
    "XDG_CACHE_HOME"  = "$userProfile\.cache"
}

# 不遵守 XDG 规范的配置路径
$toolVars = @{
  "YAZI_CONFIG_HOME" = "$userProfile\.config\yazi"
} 

# 合并字典
$allVars = $xdgVars + $toolVars

foreach ($key in $allVars.Keys) {
    $value = $allVars[$key]
    [Environment]::SetEnvironmentVariable($key, $value, "User")
    Write-Host "  -> Set $key = $value" -ForegroundColor Green
    
    # 同步创建对应的物理文件夹
    if (-not (Test-Path $value)) {
        New-Item -ItemType Directory -Path $value -Force | Out-Null
        Write-Host "  -> Created directory: $value" -ForegroundColor DarkGray
    }
}

Write-Host "`n[Success] Pure XDG variables configured! Please restart your terminal/PC to apply." -ForegroundColor Magenta
