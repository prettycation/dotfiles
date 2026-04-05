# ==================================================================================
# Windows 桌面环境启动脚本 (Admin)
#
# 功能:
# - 统一启动需要管理员权限的桌面程序
# - 每个程序的启动命令在配置区单独定义
# - 可选记录启动日志，方便排查任务计划中的问题
# ==================================================================================

# ==================================================================================
# --- [配置区域 (Your Configuration Area)] ---
# ==================================================================================

# 日志开关
$EnableLogging = $false

# 在这里定义所有需要以管理员权限启动的程序。
#
# 格式:
#   @{
#       Name    = "日志里显示的名称"
#       Command = { 启动命令 }
#       Enabled = $true   # (可选) 设置为 $false 可以暂时禁用
#   }

$AdminStartupApps = @(
    @{
        Name    = "mousemaster"
        Command = {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = "$env:SCOOP\apps\mousemaster\current\mousemaster.exe"
        $psi.WorkingDirectory = "$env:SCOOP\apps\mousemaster\current"
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        [System.Diagnostics.Process]::Start($psi) | Out-Null
        }
        Enabled = $true
    }

    # 示例:
    # ,@{
    #     Name    = "Windhawk"
    #     Command = {
    #         Start-Process `
    #             -FilePath "$env:SCOOP\apps\windhawk\current\windhawk.exe" `
    #             -ArgumentList "-tray-only"
    #     }
    #     Enabled = $true
    # }
)

# ==================================================================================
# --- [日志配置 (Logging)] ---
# ==================================================================================
$logDir  = Join-Path $HOME ".local\share\chezmoi\home\Documents\Scripts"
$logPath = Join-Path $logDir "startup-admin.log"

# ==================================================================================
# --- [核心逻辑 (Core Script Logic)] ---
# ==================================================================================

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $EnableLogging) {
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $Message" | Out-File -FilePath $logPath -Append -Encoding utf8
}

function Initialize-LogDirectory {
    if (-not $EnableLogging) {
        return
    }

    if (-not (Test-Path $logDir -PathType Container)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
}

function Start-AdminApp {
    param(
        [Parameter(Mandatory)]
        [hashtable]$App
    )

    $name = $App.Name

    if ($App.ContainsKey('Enabled') -and -not $App.Enabled) {
        Write-Log "SKIP  [$name] disabled"
        return
    }

    if (-not $App.ContainsKey('Command') -or $null -eq $App.Command) {
        throw "[$name] Command is missing."
    }

    if ($App.Command -isnot [scriptblock]) {
        throw "[$name] Command must be a script block."
    }

    Write-Log "BEGIN [$name]"
    & $App.Command
    Write-Log "OK    [$name] started successfully"
}

try {
    Initialize-LogDirectory
    Write-Log "=============================================================="
    Write-Log "startup-admin.ps1 begin"
    Write-Log "SCOOP = $env:SCOOP"

    foreach ($app in $AdminStartupApps) {
        try {
            Start-AdminApp -App $app
        }
        catch {
            Write-Log "ERROR [$($app.Name)] $($_.Exception.Message)"
            Write-Log ($_ | Out-String)
        }
    }

    Write-Log "startup-admin.ps1 end"
    Write-Log "=============================================================="
}
catch {
    Write-Log "FATAL $($_.Exception.Message)"
    Write-Log ($_ | Out-String)
    throw
}
