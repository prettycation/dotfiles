# 编码
try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
} catch {}

# 环境变量

$env:EDITOR = "nvim"

# CLAUDE_CODE
# Git Bash 路径
$env:CLAUDE_CODE_GIT_BASH_PATH = "%Scoop%\apps\git\current\bin\bash.exe"
# 禁用不必要的遥测和检查
$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"

# 函数

# 自动重绘 fastfetch
function global:Clear-Host {
    # 尝试清除屏幕
    if ($Host.Name -eq "ConsoleHost" -and [Console]::Title) {
        try { [Console]::Clear() } catch { Microsoft.PowerShell.Core\Clear-Host }
    } else {
        Microsoft.PowerShell.Core\Clear-Host
    }
    # 检查是否有 fastfetch 命令
    # 检查 $env:NVIM 是否为空 (如果不为空，则为 Neovim 内部，跳过显示)
    if ((Get-Command fastfetch -ErrorAction SilentlyContinue) -and (-not $env:NVIM)) {
        fastfetch -c "C:\Users\prettycation\.config\fastfetch\config.jsonc"
    }
}


# zy (Zoxide + Yazi with CD on quit)
# 1. 使用 fzf 模糊搜索 zoxide 的历史目录。
# 2. 在选中的目录启动 yazi。
# 3. 在 yazi 退出后，将 PowerShell 的目录也同步过去。
function zy {
    # 使用 fzf 从 zoxide 获取目标目录
    $selectedDir = zoxide query -l | fzf

    # 检查是否选择了一个目录 (而不是 Esc) 
    if ($null -ne $selectedDir) {
        # 执行与 'yy' 函数完全相同的“CD on quit”逻辑 

        # 创建一个唯一的临时文件
        $tmp = (New-TemporaryFile).FullName

        # 启动 yazi，但这次的启动目录是我们刚刚用 fzf 选中的 $selectedDir
        yazi $selectedDir --cwd-file="$tmp"

        # yazi 退出后，读取临时文件中的最终路径
        $cwd = Get-Content -Path $tmp -Encoding UTF8

        # 检查路径是否有效，并执行 cd
        if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
            Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
        }

        # 删除临时文件
        Remove-Item -Path $tmp
    }
}

# cd
# 结合 Set-Location 和 zoxide
function cd {
    param(
        [string]$Path
    )

    # 检查参数是否是一个绝对路径（以驱动器号、'~'、'\' 或 '/' 开头）
    if ($Path -match '^(~|[a-zA-Z]:|\\|/)') {
        # 如果是绝对路径，那么要求必须存在
        if (Test-Path $Path) {
            Microsoft.PowerShell.Management\Set-Location -Path $Path
        } else {
            # 如果不存在，报错
            Write-Error "Set-Location: Cannot find path '$Path' because it does not exist."
        }
    } else {
        # 若非绝对路径，交给 zoxide 处理
        z $Path
    }
}

# Yazi Shell Wrapper Function (Official Version)
# 会启动 yazi，并在退出后将 PowerShell 的目录切换到 yazi 最后所在的目录。
function yy {
    # 创建一个唯一的临时文件来存储 yazi 的 CWD (Current Working Directory)
    $tmp = (New-TemporaryFile).FullName

    # 启动 yazi，并通过 --cwd-file 参数将最终路径写入临时文件
    # $args 会将可能传递给 yy 的任何参数 (如 yy D:\some\path) 传递给 yazi
    yazi $args --cwd-file="$tmp"

    # yazi 退出后，从临时文件中读取路径
    $cwd = Get-Content -Path $tmp -Encoding UTF8

    # 检查读取到的路径是否有效，并且与当前 PowerShell 的路径不同
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        # 如果有效，就执行 cd 命令
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }

    # 删除临时文件
    Remove-Item -Path $tmp
}

function Switch-Java {
    param (
        [string]$Version
    )

    # 如果不带参数运行，则列出所有已安装的jdk版本
    if (-not $Version) {
        Write-Host "用法: jdk <版本名>" -ForegroundColor Yellow
        Write-Host "当前已安装的 Java 版本如下:"
        scoop list | Select-String "jdk"
        return
    }

    # 检查请求的版本是否已安装
    $installed = scoop list | Where-Object { $_.Name -match $Version }
    if (-not $installed) {
        Write-Host "错误: 版本 '$Version' 未安装." -ForegroundColor Red
        return
    }

    # 切换版本
    Write-Host "正在切换 Scoop 的 Java 指向..."
    scoop reset $Version

    # 获取路径
    $javaPath = scoop prefix $Version

    # 更新 JAVA_HOME 环境变量 (用户级别)
    [System.Environment]::SetEnvironmentVariable('JAVA_HOME', $javaPath, 'User')

    # 更新当前会话的 JAVA_HOME
    $env:JAVA_HOME = $javaPath

    # 从用户Path中移除所有旧的 JDK 路径，然后添加新的
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $cleanPathArray = $userPath -split ';' | Where-Object { $_ -notmatch 'scoop\\apps\\.*jdk' }
    $newPath = ($cleanPathArray + "$javaPath\bin") -join ';'
    [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')

    # 更新当前会话的 Path
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + $newPath

    Write-Host "`n✅ Java 版本已成功切换至 '$Version'!" -ForegroundColor Green
    Write-Host "   JAVA_HOME 已更新为: $env:JAVA_HOME"
    Write-Host "`n当前版本信息:"
    java -version
}

# Wi-Fi TUI 

function Open-WifiMenu {
    # 导入模块，屏蔽警告
    if (-not (Get-Module -Name WifiTools -ErrorAction SilentlyContinue)) {
        Import-Module -Name WifiTools -DisableNameChecking -ErrorAction SilentlyContinue
    }

    # 检查扫描命令是否存在
    if (Get-Command Scan-WifiAPs -ErrorAction SilentlyContinue) {
        Write-Host "Scanning for Wi-Fi networks..." -ForegroundColor Cyan

        try {
            $networks = Scan-WifiAPs -ErrorAction Stop

            if ($networks) {
                # 格式化列表
                # 使用特殊的制表符 `t 作为分隔符，防止 SSID 中间有空格导致解析错误
                # 格式：SSID (制表符) 信号强度
                $formatted_list = $networks | ForEach-Object {
                    "{0}`t[Signal: {1}]" -f $_.Name, $_.Signal
                }

                # 调用 fzf
                $selected_line = $formatted_list | fzf --ansi --prompt="Select Wi-Fi > "

                if (-not [string]::IsNullOrWhiteSpace($selected_line)) {
                    # 解析 SSID
                    # 使用制表符分割，只取第一部分，这样就能完美处理带空格的 WiFi 名
                    $selected_ssid = $selected_line -split "`t" | Select-Object -First 1

                    if (-not [string]::IsNullOrWhiteSpace($selected_ssid)) {
                        Write-Host "Connecting to '$selected_ssid'..." -ForegroundColor Yellow
                        # 使用 netsh 连接 (仅适用于已保存过密码的网络)
                        netsh wlan connect name="$selected_ssid"
                    }
                } else {
                    Write-Host "No network selected." -ForegroundColor DarkGray
                }
            } else {
                Write-Host "No Wi-Fi networks found." -ForegroundColor Red
            }
        } catch {
            Write-Host "Error during scan: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Error: WifiTools module not found or scan command missing." -ForegroundColor Red
    }
}

# 断开连接函数 (自动查找接口名)
function Close-WifiConnection {
    Write-Host "Disconnecting..." -ForegroundColor Yellow

    # 自动获取当前活动的无线接口名称
    # netsh wlan show interfaces 输出中包含 "Name : Wi-Fi" 这样的行
    $interfaceLine = netsh wlan show interfaces | Select-String "\sName\s+:\s+(.+)"

    if ($interfaceLine) {
        # 提取接口名称
        $interfaceName = $interfaceLine.Matches.Groups[1].Value.Trim()
        # 指定接口断开，防止报错 "No such wireless interface"
        netsh wlan disconnect interface="$interfaceName"
    } else {
        # 如果获取失败，尝试默认断开
        netsh wlan disconnect
    }
}

function hl.history {
    Get-History | Select-Object `
        @{n='time';e={$_.StartExecutionTime}}, `
        @{n='level';e={'INFO'}}, `
        @{n='message';e={$_.CommandLine}}, `
        @{n='duration';e={$_.Duration.TotalSeconds.ToString("0.00") + 's'}} `
    | ForEach-Object { $_ | ConvertTo-Json -Compress } | hl
}

Remove-Item alias:ls -Force -ErrorAction SilentlyContinue

# 基础 ls 命令，只设置图标。
function ls { eza.exe --icons @args }

# ll (long list), 在这里我们定义详细格式和时间格式。
#    @args 允许你传递额外参数, 比如 ll C:\Users
function ll { eza.exe -l -h --icons --time-style '+%Y-%m-%d %H:%M:%S' @args }

# la (list all), 基于 ll 添加 -a (显示所有文件) 参数。
function la { eza.exe -l -h -a --icons --time-style '+%Y-%m-%d %H:%M:%S' @args }

# lg (list git), 基于 la 添加 --git 参数。
function lg { eza.exe -l -h -a --git --icons --time-style '+%Y-%m-%d %H:%M:%S' @args }

# tree, 显示目录树。
function tree { eza.exe -T --icons @args }

# condaini，用于初始化 conda
function condaini {
    conda shell.powershell hook | Out-String | Invoke-Expression
}


# 别名
if (-not (Get-Alias clear -ErrorAction SilentlyContinue)) { Set-Alias clear Clear-Host }
if (-not (Get-Alias cls -ErrorAction SilentlyContinue)) { Set-Alias cls Clear-Host }
Set-Alias -Name sudo -Value gsudo
Import-Module gsudoModule

# 为 Switch-Java 函数设置一个更短的别名'jdk'
Set-Alias -Name jdk -Value Switch-Java

# Connect/Disconnect-Wif 别名
Set-Alias -Name cw -Value Open-WifiMenu -Force
Set-Alias -Name dw -Value Close-WifiConnection -Force

# 模块加载与配置

# hl (human log) 自动补全配置
# 检查 hl 命令是否存在，避免未安装时报错
if (Get-Command hl -ErrorAction SilentlyContinue) {
    # 动态生成补全脚本并执行
    hl --shell-completions powershell | Out-String | Invoke-Expression
}

# ——— 配置 PSReadLine (补全、历史记录等)
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler {
    param($Mode)

    if ($Mode -eq 'Command') {
        # Command 模式 -> 实心方块 (Blinking Block)
        Write-Host -NoNewline "`e[1 q"
    } else {
        # Insert 模式 -> 竖线 (Blinking Bar)
        Write-Host -NoNewline "`e[5 q"
    }
}
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo
Set-PSReadLineOption -Colors @{
    # Catppuccin Mocha Palette
    Default                = "`e[38;2;205;214;244m" # Text
    Comment                = "`e[38;2;108;112;134m" # Overlay0
    Keyword                = "`e[38;2;203;166;247m" # Mauve
    String                 = "`e[38;2;166;227;161m" # Green
    Operator               = "`e[38;2;137;220;235m" # Sky
    Variable               = "`e[38;2;249;226;175m" # Yellow
    Command                = "`e[38;2;137;180;250m" # Blue
    Parameter              = "`e[38;2;180;190;254m" # Lavender
    Type                   = "`e[38;2;249;226;175m" # Yellow
    Number                 = "`e[38;2;250;179;135m" # Peach
    Member                 = "`e[38;2;205;214;244m" # Text
    Error                  = "`e[38;2;243;139;168m" # Red
    ContinuationPrompt     = "`e[38;2;205;214;244m" # Text
    Emphasis               = "`e[38;2;148;226;213m" # Teal
    ListPrediction         = "`e[38;2;108;112;134m" # Overlay0
    ListPredictionSelected = "`e[48;2;69;71;90m"   # Surface1 background
    InlinePrediction       = "`e[38;2;108;112;134m" # Overlay0
}

# 自动执行逻辑

# Neovim Venv/Conda 自动激活

# 获取当前环境路径：优先取 VIRTUAL_ENV (uv/venv)，如果没有则取 CONDA_PREFIX (Conda)
$currentEnv = if ($env:VIRTUAL_ENV) { $env:VIRTUAL_ENV } else { $env:CONDA_PREFIX }

if ($currentEnv) {
    # 尝试寻找标准的 Activate.ps1 (uv, venv, poetry)
    $venvScript = Join-Path $currentEnv "Scripts\Activate.ps1"

    if (Test-Path $venvScript) {
        # 情况 A: 标准 Venv
        Write-Host "⚡ Auto-activating Venv (uv/std)..." -ForegroundColor Green
        & $venvScript
    } else {
        # 情况 B: Conda 环境
        if (Get-Command conda -ErrorAction SilentlyContinue) {
            Write-Host "⚡ Auto-activating Conda..." -ForegroundColor Green

            # 注册 Hook (让 conda activate 生效)
            (& conda "shell.powershell" "hook") | Out-String | Invoke-Expression

            # 提取环境名
            $envName = Split-Path $currentEnv -Leaf

            # 激活
            conda activate $envName

            # 确保 Starship 也能看到名字
            if (-not $env:CONDA_DEFAULT_ENV) {
                $env:CONDA_DEFAULT_ENV = $envName
            }
        }
    }
}

# 初始显示 Fastfetch
Clear-Host

# ——— WezTerm Shell Integration (OSC 7) ———
# 在第一个 Pane/选项卡/窗口之后创建的 Pane/选项卡/窗口通常会尝试解析当前 Pane 的当前工作目录，优先使用由 OSC 7 设置的值（../shell-integration.md），如果没有则退回到尝试查找附加到本地 Pane 的当前进程组组长的 cwd。如果无法解析任何 cwd，则使用 default_cwd。
# 定义在 starship init 之前，Starship 会自动调用此钩子函数
function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        # 将 Windows 路径斜杠替换为 URI 标准的斜杠
        $provider_path = $current_location.ProviderPath -replace "\\", "/"
        # 发送 OSC 7 序列告知 WezTerm 当前目录
        $osc7 = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
        $host.ui.Write($osc7)
    }
}

# 工具初始化钩子

#  加载社区提供的额外 Tab 补全规则
Import-Module PSCompletions

# 绘制命令提示符
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\montys.omp.json" | Invoke-Expression
Invoke-Expression (&starship init powershell)

# 配置 FZF 默认选项 (配色方案)
$ENV:FZF_DEFAULT_OPTS=@"
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8
--color=selected-bg:#45475A
--color=border:#6C7086,label:#CDD6F4
"@

# 将 scoop-search 集成到 PowerShell
# Invoke-Expression (&scoop-search --hook)
#([ScriptBlock]::Create((& scoop-search --hook | Out-String)))

# 将 sfsu 集成到 PowerShell
Invoke-Expression (&sfsu hook --disable cleanup --disable cache --disable status --disable info --disable bucket --disable export)

# Zoxide (smart cd) Initialization
# 将 zoxide 的钩子注入到修改过的提示符中。
Invoke-Expression (& { (zoxide init powershell) -join "`n" })

# 将 tv 的钩子注入到修改过的提示符中
Invoke-Expression (& { (tv init power-shell) -join "`n" })

# 初始化 md

Import-Module MessageDump
