param(
    [Parameter(Mandatory = $true)]
    $Context
)

$ErrorActionPreference = "Stop"

Write-Step "Initializing XDG Environment"

# 行为：
#   1. 写入 User 级环境变量
#   2. 同步到当前会话
#   3. 创建对应目录

# 幂等性：
#   - 已存在的目录不会重复创建
#   - 已存在的变量会被覆盖为当前约定值，确保环境一致

$xdgMap = Get-XdgEnvironmentMap

if ($null -eq $xdgMap -or $xdgMap.Count -eq 0) {
    throw "Get-XdgEnvironmentMap returned no values."
}

foreach ($key in $xdgMap.Keys) {
    $value = [string]$xdgMap[$key]

    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Resolved XDG path for '$key' is empty."
    }

    $previousUserValue = [System.Environment]::GetEnvironmentVariable($key, "User")

    Set-UserEnvironmentVariable -Name $key -Value $value

    if ($previousUserValue -ne $value) {
        Write-Host "  -> Set $key = $value" -ForegroundColor Green
    } else {
        Write-Host "  -> $key already set to $value" -ForegroundColor DarkGray
    }

    if (-not (Test-Path $value)) {
        Ensure-DirectoryExists -Path $value
        Write-Host "  -> Created directory: $value" -ForegroundColor Green
    } else {
        Write-Host "  -> Directory exists: $value" -ForegroundColor DarkGray
    }
}

# 某些后续步骤（如 mise / chezmoi / yazi 相关路径）会依赖这些变量，
# 所以这里再统一刷新一次当前会话 PATH/环境感知。
Update-PathEnvironment

Write-OK "XDG environment initialized for current user"
