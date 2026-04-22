return {
  "folke/snacks.nvim",
  cond = not vim.g.vscode,
  opts = {
    explorer = {
      replace_netrw = false, -- 禁用自动打开 explorer
    },
  },
  -- 迁移至 init.lua
  -- init = function()
  --   -- 禁用 netrw (Vim 的内置文件浏览器)
  --   vim.g.loaded_netrw = 1
  --   vim.g.loaded_netrwPlugin = 1
  -- end,
}
