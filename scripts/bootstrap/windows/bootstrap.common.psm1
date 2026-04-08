# bootstrap.common.psm1

# 作用：
#   这是 bootstrap 的共享模块，放“可复用、与具体步骤无关”的公共函数。
#   主入口 bootstrap.ps1 和各 steps/*.ps1 只负责调用这里的函数，不再重复定义 helper。

# 设计边界：
#   - 日志、环境探测、manifest 读取、Scoop 安装、XDG 初始化、mise 校验、chezmoi 状态查询

Set-StrictMode -Version Latest

function Write-Step {
    <#
    .SYNOPSIS
        输出阶段标题。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "`n━━━ $Message ━━━" -ForegroundColor Cyan
}

function Write-OK {
    <#
    .SYNOPSIS
        输出成功信息。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Warn {
    <#
    .SYNOPSIS
        输出警告信息。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "  ⚠ $Message" -ForegroundColor Yellow
}

function Test-CommandExists {
    <#
    .SYNOPSIS
        检查命令是否可用。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Assert-RunningAsAdministrator {
    <#
    .SYNOPSIS
        要求当前 PowerShell 以管理员身份运行。
    #>
    [CmdletBinding()]
    param()

    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "This bootstrap must be run in an elevated PowerShell session (Run as Administrator)."
    }
}

function Update-PathEnvironment {
    <#
    .SYNOPSIS
        从注册表重新加载 Machine/User PATH 到当前会话。
    .DESCRIPTION
        适用于本次会话内刚安装 Scoop / pwsh / mise 等工具后，立即让后续步骤可见。
    #>
    [CmdletBinding()]
    param()

    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
    Write-Host "  ⟳ PATH refreshed" -ForegroundColor DarkGray
}

function Ensure-DirectoryExists {
    <#
    .SYNOPSIS
        确保目录存在，不存在则创建。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Get-RepoRoot {
    <#
    .SYNOPSIS
        从 bootstrap 目录向上查找 dotfiles 仓库根目录。
    .DESCRIPTION
        通过检查 manifests/windows.packages.json 是否存在来识别 repo root，
        避免因为 bootstrap 脚本目录层级变化导致路径计算错误。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BootstrapRoot
    )

    $current = (Resolve-Path $BootstrapRoot).Path

    while (-not [string]::IsNullOrWhiteSpace($current)) {
        $manifestPath = Join-Path $current "manifests\windows.packages.json"
        if (Test-Path $manifestPath) {
            return $current
        }

        $parent = Split-Path $current -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current) {
            break
        }

        $current = $parent
    }

    throw "Could not locate repo root from bootstrap root '$BootstrapRoot'. Expected to find manifests\windows.packages.json in some parent directory."
}

function New-BootstrapContext {
    <#
    .SYNOPSIS
        创建 bootstrap 共享上下文对象。
    .DESCRIPTION
        后续各步骤脚本统一接收 Context，避免重复计算 repo 路径、重复读取 manifest。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BootstrapRoot,

        [string]$ChezmoiRepo = "",
        [string]$DevDrive = "",
        [bool]$SkipChezmoi = $false
    )

    $repoRoot = Get-RepoRoot -BootstrapRoot $BootstrapRoot

    return [PSCustomObject]@{
        BootstrapRoot   = $BootstrapRoot
        RepoRoot        = $repoRoot
        ChezmoiRepo     = $ChezmoiRepo
        DevDrive        = $DevDrive
        SkipChezmoi     = $SkipChezmoi
        WindowsPackages = $null
        WindowsRuntimes = $null
    }
}

function Get-ManifestJson {
    <#
    .SYNOPSIS
        从仓库根读取 JSON manifest。
    .PARAMETER RepoRoot
        dotfiles 仓库根目录。
    .PARAMETER RelativePath
        相对 RepoRoot 的路径，例如 manifests\windows.packages.json
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $manifestPath = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path $manifestPath)) {
        throw "Manifest not found: $manifestPath"
    }

    return Get-Content $manifestPath -Raw | ConvertFrom-Json -Depth 30
}

function Assert-ManifestHasScoopGroups {
    <#
    .SYNOPSIS
        确保 windows.packages.json 已经是新结构（scoopGroups）。
    .DESCRIPTION
        旧结构依赖 optional/scoopTools；当前 bootstrap 将只支持 scoopGroups。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$WindowsPackages
    )

    if ($WindowsPackages.PSObject.Properties["optional"]) {
        Write-Warn "Legacy manifest field 'optional' detected; bootstrap now expects scoopGroups."
    }

    if (-not $WindowsPackages.PSObject.Properties["scoopGroups"]) {
        throw "Manifest does not contain scoopGroups. Re-run export script to regenerate manifests/windows.packages.json."
    }
}

function Set-UserEnvironmentVariable {
    <#
    .SYNOPSIS
        设置 User 级环境变量，并同步到当前会话。
    .DESCRIPTION
        适合 XDG / DevDrive 一类机器本地初始化变量。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    [System.Environment]::SetEnvironmentVariable($Name, $Value, "User")
    Set-Item -Path "Env:$Name" -Value $Value
}

function Get-XdgEnvironmentMap {
    <#
    .SYNOPSIS
        返回 Windows 下要使用的 XDG 相关环境变量映射。
    .DESCRIPTION
        这里只返回键值，不直接写入；具体写入由调用方决定，便于步骤脚本控制输出和时机。
    #>
    [CmdletBinding()]
    param()

    $userProfile = $env:USERPROFILE

    return [ordered]@{
        "XDG_CONFIG_HOME" = "$userProfile\.config"
        "XDG_DATA_HOME"   = "$userProfile\.local\share"
        "XDG_STATE_HOME"  = "$userProfile\.local\state"
        "XDG_CACHE_HOME"  = "$userProfile\.cache"
        "YAZI_CONFIG_HOME" = "$userProfile\.config\yazi"
    }
}

function Initialize-XdgDirectories {
    <#
    .SYNOPSIS
        初始化 XDG 目录及对应的 User 环境变量。
    .DESCRIPTION
        这是机器本地初始化步骤，不属于 chezmoi 模板渲染职责。
    #>
    [CmdletBinding()]
    param()

    $vars = Get-XdgEnvironmentMap

    foreach ($key in $vars.Keys) {
        $value = [string]$vars[$key]

        Set-UserEnvironmentVariable -Name $key -Value $value
        Write-Host "  -> Set $key = $value" -ForegroundColor Green

        Ensure-DirectoryExists -Path $value
        Write-Host "  -> Ensured directory: $value" -ForegroundColor DarkGray
    }
}

function Install-ScoopApp {
    <#
    .SYNOPSIS
        安装单个 Scoop 包（幂等）。
    .DESCRIPTION
        对已安装包直接跳过；对非 main bucket 自动使用 bucket/package 形式安装。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$App,

        [string]$Bucket = "main"
    )

    $packageRef = if ($Bucket -and $Bucket -ne "main") { "$Bucket/$App" } else { $App }

    if (-not (scoop info $packageRef 2>&1 | Select-String "Installed")) {
        Write-Host "  Installing $packageRef..." -ForegroundColor Gray
        scoop install $packageRef
        Write-OK "$App installed"
    } else {
        Write-OK "$App already installed"
    }
}

function Get-MiseRuntimeCommand {
    <#
    .SYNOPSIS
        根据 runtime spec 推导校验命令名。
    .DESCRIPTION
        例如 rust@stable -> rustc，python@3.12 -> python。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RuntimeSpec
    )

    $runtimeName = ($RuntimeSpec -split "@")[0].ToLowerInvariant()
    switch ($runtimeName) {
        "rust"   { return "rustc" }
        "python" { return "python" }
        default  { return $runtimeName }
    }
}

function Test-MiseRuntimeCommands {
    <#
    .SYNOPSIS
        校验 mise 安装后的运行时命令是否已出现在 PATH。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$RuntimeSpecs
    )

    $missing = @()

    foreach ($runtime in $RuntimeSpecs) {
        $command = Get-MiseRuntimeCommand -RuntimeSpec $runtime
        if (-not (Test-CommandExists $command)) {
            $resolvedPath = ""
            try {
                $resolvedPath = (& mise which $command 2>$null | Out-String).Trim()
            } catch {
                $resolvedPath = ""
            }

            $missing += [PSCustomObject]@{
                Runtime      = $runtime
                Command      = $command
                MiseResolved = if ($resolvedPath) { $resolvedPath } else { "<not found by mise which>" }
            }
        }
    }

    if ($missing.Count -gt 0) {
        Write-Warn "mise runtime validation failed. Commands missing from PATH:"
        foreach ($item in $missing) {
            Write-Warn "  runtime=$($item.Runtime) command=$($item.Command) miseWhich=$($item.MiseResolved)"
        }
        throw "Runtime validation failed. Ensure MISE_DATA_DIR shims are on PATH, then run 'mise reshim'."
    }

    Write-OK "Validated runtime commands on PATH"
}

function Get-ChezmoiSourcePath {
    <#
    .SYNOPSIS
        返回当前 chezmoi source path；未初始化则返回空字符串。
    .DESCRIPTION
        这里只做状态查询，不负责初始化。
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-CommandExists "chezmoi")) { return "" }

    try {
        return (& chezmoi source-path 2>$null | Out-String).Trim()
    } catch {
        return ""
    }
}

function Get-ChezmoiRemoteOrigin {
    <#
    .SYNOPSIS
        返回当前 chezmoi source repo 的 origin URL；不可用则返回空字符串。
    .DESCRIPTION
        仅用于状态展示或手动后续步骤提示。
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-CommandExists "chezmoi")) { return "" }

    try {
        return (& chezmoi git -- remote get-url origin 2>$null | Out-String).Trim()
    } catch {
        return ""
    }
}

function Test-ChezmoiHasManagedFiles {
    <#
    .SYNOPSIS
        检查当前 chezmoi 是否已有 managed targets。
    .DESCRIPTION
        仅做状态探测，不自动触发 init/apply。
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-CommandExists "chezmoi")) { return $false }

    try {
        $managed = (& chezmoi managed 2>$null | Out-String).Trim()
        return -not [string]::IsNullOrWhiteSpace($managed)
    } catch {
        return $false
    }
}

function Get-ManualChezmoiNextSteps {
    <#
    .SYNOPSIS
        返回建议的手动 chezmoi / Bitwarden 后续步骤文本。
    .DESCRIPTION
        新 bootstrap 只准备工具和环境，不自动执行私密配置落盘。
    #>
    [CmdletBinding()]
    param(
        [string]$RepoHint = ""
    )

    $repoText = if ([string]::IsNullOrWhiteSpace($RepoHint)) { "<repo-or-path>" } else { $RepoHint }

    return @"
Manual next steps:
  1. Authenticate Bitwarden:
       bw login
       bw unlock

  2. Export your BW session for this shell:
       `$env:BW_SESSION = "<session>"

  3. Initialize / apply chezmoi manually:
       chezmoi init $repoText
       chezmoi apply
"@
}

Export-ModuleMember -Function @(
    "Write-Step",
    "Write-OK",
    "Write-Warn",
    "Test-CommandExists",
    "Assert-RunningAsAdministrator",
    "Update-PathEnvironment",
    "Ensure-DirectoryExists",
    "Get-RepoRoot",
    "New-BootstrapContext",
    "Get-ManifestJson",
    "Assert-ManifestHasScoopGroups",
    "Set-UserEnvironmentVariable",
    "Get-XdgEnvironmentMap",
    "Initialize-XdgDirectories",
    "Install-ScoopApp",
    "Get-MiseRuntimeCommand",
    "Test-MiseRuntimeCommands",
    "Get-ChezmoiSourcePath",
    "Get-ChezmoiRemoteOrigin",
    "Test-ChezmoiHasManagedFiles",
    "Get-ManualChezmoiNextSteps"
)
