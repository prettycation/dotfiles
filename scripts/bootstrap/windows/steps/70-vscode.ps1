param(
  [Parameter(Mandatory = $true)]
  $Context
)

$ErrorActionPreference = "Stop"

Write-Step "Installing VS Code Extensions"

# 说明：
#   这一步只负责“同步 VS Code 扩展”，不负责安装 VS Code 本体。

# 边界：
#   - 如果系统里没有 `code` 命令，则直接跳过
#   - 如果存在 tasks/install-vscode-extensions.ps1，则调用它
#   - 如果扩展脚本不存在，则给出清晰报错

# 设计原因：
#   VS Code 是否安装，取决于前面的 Scoop group 选择；
#   这里只有在 VS Code 已经存在的前提下，才进行扩展同步。

if (-not (Test-CommandExists "code"))
{
  Write-Host "  VS Code CLI (code) is not available; skipping extension install." -ForegroundColor DarkGray
  Write-OK "VS Code step skipped"
  return
}

$extensionScript = Join-Path $Context.BootstrapRoot "tasks\install-vscode-extensions.ps1"

if (-not (Test-Path $extensionScript))
{
  throw "VS Code extension script not found: $extensionScript"
}

Write-Host "  Using extension script: $extensionScript" -ForegroundColor Gray

try
{
  & $extensionScript
  Write-OK "VS Code extensions processed"
} catch
{
  throw "VS Code extension installation failed: $_"
}
