-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "typst", "txt" },

  callback = function()
    vim.opt_local.spell = false
  end,
})

-- 退出 nvim 后恢复默认光标
vim.api.nvim_create_autocmd("VimLeave", {
  group = vim.api.nvim_create_augroup("RestoreCursor", { clear = true }),
  callback = function()
    -- 重置 guicursor 选项
    vim.opt.guicursor = ""
    -- 使用 chansend 向 stderr 发送 "\27[ q" (重置为终端默认形状)
    -- \27 是 Esc 键的转义码
    vim.fn.chansend(vim.v.stderr, "\27[ q")
  end,
})
