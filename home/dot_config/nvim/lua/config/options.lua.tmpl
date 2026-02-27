-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.linebreak = true -- 换行时不会从单词中间断开
vim.opt.breakindent = true -- 换行后保持缩进

if vim.fn.has("win32") == 1 then
  -- 使用 schedule 确保在 LazyVim 加载完默认配置后覆盖
  vim.schedule(function()
    -- 指定 Shell (使用 .exe 明确路径)
    vim.opt.shell = vim.fn.executable("pwsh") == 1 and "pwsh.exe" or "powershell.exe"
    vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    vim.opt.shellquote = ""
    vim.opt.shellxquote = ""

    -- 标准重定向，确保 Lua 能读到输出
    vim.opt.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  end)
end

if vim.g.vscode then
  vim.notify = require("vscode").notify
  vim.g.clipboard = vim.g.vscode_clipboard
  vim.cmd.syntax("off")
  return
end
