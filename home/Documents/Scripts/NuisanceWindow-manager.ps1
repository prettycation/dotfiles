# ==================================================================================
# Nuisance Window Manager (流氓窗口管理器)

# 功能:
# - 在桌面环境加载完毕后，自动关闭列表中指定的“流氓”进程。
#
# 由计划任务调用：
#   Startup - Nuisance Window Manager (Admin)

# 设计要求：
# - 非交互：不能 Read-Host / pause；
# - 容错：目标进程不存在或已退出时不让任务失败；
# - 幂等：重复运行不会产生副作用。
# ==================================================================================

$ErrorActionPreference = "Continue"

# --- 配置区域 ---
# 在开机后自动关闭的程序的“进程名”(不含.exe)
$nuisanceProcesses = @(
  @{
    ProcessName = "ControlCenterDaemon"
    Comment     = "神舟风扇控制程序"
  }

  # 示例: "AnnoyingPopup.exe"
  # ,@{
  #     ProcessName = "AnnoyingPopup"
  #     Comment     = "一个烦人的弹窗程序"
  # }
)

# 等待 explorer.exe 的最长超时时间（秒）
$waitTimeoutSeconds = 120

Write-Host "--- [NWM] Nuisance Window Manager starting ---" -ForegroundColor Cyan

# 等待桌面环境加载 (等待 explorer.exe 进程出现)
# 确保脚本执行时，用户桌面已经初始化，目标进程也已经启动。
Write-Host "[NWM] Waiting for the desktop environment (explorer.exe) to be ready..."

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

while ($stopwatch.Elapsed.TotalSeconds -lt $waitTimeoutSeconds)
{
  # -ErrorAction SilentlyContinue 确保在找不到进程时不会报错
  if (Get-Process -Name "explorer" -ErrorAction SilentlyContinue)
  {
    Write-Host "[NWM] Desktop is ready! (explorer.exe found)" -ForegroundColor Green

    # 桌面进程已找到，额外再等待一小段时间（3秒），让桌面上的其他应用有机会完成加载。
    Start-Sleep -Seconds 3
    break # 退出等待循环
  }

  # 每隔半秒检查一次，避免CPU占用过高
  Start-Sleep -Milliseconds 500
}

if ($stopwatch.Elapsed.TotalSeconds -ge $waitTimeoutSeconds)
{
  Write-Warning "[NWM] Timed out waiting for explorer.exe after $waitTimeoutSeconds seconds. The script will continue, but might fail to find target processes."
}

$stopwatch.Stop()

# 遍历并关闭目标进程
foreach ($item in $nuisanceProcesses)
{
  $processName = [string]$item.ProcessName
  $comment = [string]$item.Comment

  if ([string]::IsNullOrWhiteSpace($processName))
  {
    Write-Warning "[NWM] Empty process name, skip."
    continue
  }

  Write-Host "[NWM] Searching for process across all users: '$comment' (Process: $processName)"

  try
  {
    # 获取系统上的〖所有〗进程，然后通过 Where-Object 进行手动筛选。
    $processesToStop = @(
      Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -eq $processName }
    )

    if ($processesToStop.Count -gt 0)
    {
      # 使用数组 Count 计数，即使只有一个进程对象也稳定。
      Write-Host "[NWM] Found $($processesToStop.Count) instance(s) of '$processName'. Force stopping..." -ForegroundColor Green

      # 通过管道将找到的进程对象传递给 Stop-Process 来终止。
      $processesToStop | Stop-Process -Force -ErrorAction Continue

      Write-Host "[NWM] Process '$processName' stopped successfully."
    } else
    {
      # 如果 $processesToStop 为空，说明没有找到匹配的进程。
      Write-Host "[NWM] Process '$processName' not found on the system." -ForegroundColor Yellow
    }
  } catch
  {
    # 捕获 Stop-Process 可能出现的其他错误，例如权限不足或进程已在操作期间退出。
    Write-Warning "[NWM] An error occurred while trying to stop '$processName': $($_.Exception.Message)"
  }
}

Write-Host "--- [NWM] Nuisance Window Manager finished ---" -ForegroundColor Cyan
