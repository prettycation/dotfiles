<#
.SYNOPSIS
    Universal Startup Task Manager - 一个声明式的 Windows 任务计划管理脚本。

.DESCRIPTION
    此脚本通过读取一个简单的 PowerShell 列表 ($Tasks)，自动在 Windows 任务计划程序中
    创建、更新或同步所有指定的开机自启动任务。
    它能够为每个任务独立配置是否需要免UAC的管理员权限，并包含了多项健壮性检查。

.NOTES
    Requires: PowerShell with Administrator privileges.

.USAGE
    1. 在下面的 "$Tasks" 列表中，配置您想要管理的自启动任务。
    2. 以【管理员权限】运行此脚本: .\Setup-AdminAutoStart.ps1
    3. 脚本将自动完成所有任务的同步。
#>

# ==================================================================================
# --- [配置区域 (Your Configuration Area)] ---
# ==================================================================================
# 在这里定义所有您希望开机自启的任务。
#
# 格式 (Format):
#   @{
#       Name    = "任务的唯一名称 (会显示在任务计划程序里)"
#       Command = "要执行的完整命令 (例如，一个 .exe 的路径或一个 PowerShell 命令)"
#       Admin   = $true  # 如果需要免UAC的管理员权限
#                 $false # 如果只需要普通用户权限
#       Enabled = $true  # (可选) 设置为 $false 可以暂时禁用这个任务的创建
#   }

$Tasks = @(
    @{
        Name    = "Startup - Nuisance Window Manager (Admin)"
        Command = "powershell.exe -ExecutionPolicy Bypass -File `"$env:USERPROFILE\Documents\Scripts\NuisanceWindow-manager.ps1`""
        Admin   = $true
        Enabled = $true
    },
    @{
        Name    = "Startup - Desktop Environment (Apps)"
        Command = "powershell.exe -ExecutionPolicy Bypass -File `"$env:USERPROFILE\Documents\Scripts\startup.ps1`""
        Admin   = $false
        Enabled = $true
    }
    # 【示例】如果要添加一个新的普通任务:
    # ,@{
    #    Name    = "Startup - My New App"
    #    Command = "C:\Path\To\MyNewApp.exe"
    #    Admin   = $false
    #    Enabled = $true
    # }
)


# ==================================================================================
# --- [核心逻辑 (Core Script Logic)] ---
# ==================================================================================

# 1. 权限检查 (Administrator Check)
#    确保脚本是以管理员身份运行的，否则无法创建任务计划。
if (-NOT ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "此脚本需要管理员权限来创建/更新任务计划。"
    Read-Host "按 Enter 键退出。"
    exit
}

# 2. 获取当前用户信息 (Get Current User)
#    使用 .NET 类，这是最可靠的方法，兼容直接运行和通过 sudo/gsudo 运行的场景。
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$startupFolderPath = [Environment]::GetFolderPath('Startup')

Write-Host "=================================================================="
Write-Host " Starting Task Synchronization for user: $CurrentUser"
Write-Host "=================================================================="

# 3. 遍历并处理任务列表 (Process Task List)
foreach ($Task in $Tasks) {
    # 如果任务被禁用，则跳过
    if ($Task.ContainsKey('Enabled') -and -not $Task.Enabled) {
        Write-Host ""
        Write-Host "Skipping disabled task: '$($Task.Name)'..." -ForegroundColor Gray
        continue
    }

    $TaskName = $Task.Name
    $CommandToRun = $Task.Command
    $IsAdmin = $Task.Admin

    Write-Host ""
    Write-Host "Processing Task: '$TaskName'..." -ForegroundColor Cyan

    # a. 路径存在性检查 (Path Existence Check for script files)
    #    从命令中提取 PowerShell 脚本路径并检查其是否存在。
    if ($CommandToRun -match '-File\s+`"([^`"]+)`"') {
        $scriptPath = $matches[1]
        if (-not (Test-Path $scriptPath -PathType Leaf)) {
            Write-Error "  -> FAILED: Script file not found at path: '$scriptPath'"
            continue # 跳过这个任务，继续处理下一个
        }
    }

    # b. 检测旧的快捷方式冲突 (Check for conflicting shortcuts in startup folder)
    $conflictingFiles = Get-ChildItem -Path $startupFolderPath -Filter "*.lnk" -Recurse | Where-Object {
        try {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($_.FullName)
            # 检查快捷方式的目标是否与当前任务的命令相关
            $shortcut.TargetPath -like "*$($Task.Name)*" -or $shortcut.Arguments -like "*$($Task.Name)*"
        } catch { $false }
    }
    if ($conflictingFiles) {
        Write-Warning "  -> WARNING: Found a potentially conflicting shortcut in the startup folder: $($conflictingFiles.Name)"
    }

    # c. 创建或更新任务计划 (Create/Update Scheduled Task)
    try {
        # schtasks.exe 参数详解:
        # /Create /F        : 创建或强制覆盖
        # /TN <TaskName>    : 任务的名称
        # /TR <TaskRun>     : 要执行的命令
        # /SC ONLOGON       : 触发器 - 在指定用户登录时
        # /RU <CurrentUser> : 以哪个用户身份运行
        # /RL HIGHEST       : (管理员模式) 以最高权限运行，用于跳过UAC
        if ($IsAdmin) {
            Write-Host "  -> Mode: Admin (Highest Privileges, Skip UAC)"
            schtasks.exe /Create /F /TN "$TaskName" /TR "$CommandToRun" /SC ONLOGON /RU "$CurrentUser" /RL HIGHEST
        } else {
            Write-Host "  -> Mode: Standard User"
            schtasks.exe /Create /F /TN "$TaskName" /TR "$CommandToRun" /SC ONLOGON /RU "$CurrentUser"
        }
        Write-Host "  -> SUCCESS: Task '$TaskName' has been created/updated successfully." -ForegroundColor Green
    } catch {
        Write-Error "  -> FAILED: An error occurred while creating task '$TaskName': $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "=================================================================="
Write-Host " Task Synchronization Complete."
Write-Host "=================================================================="
Read-Host " Press Enter to exit."
