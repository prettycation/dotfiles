-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim.keymap.set("i", "jk", "<Esc>", { desc = "退出插入模式", silent = true })

-- vim.keymap.set("c", "jk", "<Esc>", { desc = "退出命令模式", silent = true })

pcall(vim.keymap.del, "n", "<leader>gd")
pcall(vim.keymap.del, "n", "<leader>gD")
pcall(vim.keymap.del, "n", "<leader>gf")

vim.keymap.set("n", "<leader>gd", "<cmd>CodeDiff<cr>", {
  desc = "Git Diff (CodeDiff)",
  silent = true,
})

vim.keymap.set("n", "<leader>gD", "<cmd>CodeDiff origin/HEAD<cr>", {
  desc = "Git Diff origin/HEAD (CodeDiff)",
  silent = true,
})

vim.keymap.set("n", "<leader>gf", "<cmd>CodeDiff history HEAD~50 %<cr>", {
  desc = "Git Current File History (CodeDiff)",
  silent = true,
})

if vim.g.vscode then
  -- 清理 vscode-neovim 默认的 m 开头的多光标映射，解决 m 键延迟
  local function remove_conflict_keys()
    pcall(vim.keymap.del, "x", "ma")
    pcall(vim.keymap.del, "x", "mi")
    pcall(vim.keymap.del, "x", "mA")
    pcall(vim.keymap.del, "x", "mI")
  end
  remove_conflict_keys()
  local vscode = require("vscode")

  -- 将 Space 键映射为调用 VSCode 的 whichkey.show 命令
  vim.keymap.set("n", "<space>", function()
    vscode.action("whichkey.show")
  end)
end
