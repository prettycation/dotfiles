# ==================================================================================
# Windows 桌面环境启动脚本
# ==================================================================================

# --- 启动Windhawk ---

Start-Process -FilePath "$env:Scoop\apps\windhawk\current\windhawk.exe" -ArgumentList "-tray-only"
Start-Sleep -Seconds 1

# --- 启动状态栏 ---

Start-Process -FilePath "$env:Scoop\apps\AmN.yasb\current\app\yasb.exe"
Start-Sleep -Seconds 1

# --- 启动窗口管理器 ---

Start-Process -FilePath "$env:Scoop\apps\glazewm\current\glazewm.exe"
Start-Sleep -Seconds 1
