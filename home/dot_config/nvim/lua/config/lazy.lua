local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- lazy extras
    { import = "lazyvim.plugins.extras.coding.yanky", cond = not vim.g.vscode },

    -- import/override with your plugins
    { import = "plugins" },
    { import = "plugins.lsp", cond = not vim.g.vscode },
    { import = "plugins.lang", cond = not vim.g.vscode },
    { import = "plugins.ai", cond = not vim.g.vscode },
    { import = "plugins.git", cond = not vim.g.vscode },
    { import = "plugins.coding", cond = not vim.g.vscode },
    { import = "plugins.editor" },
    { import = "plugins.completion", cond = not vim.g.vscode },
    { import = "plugins.preview", cond = not vim.g.vscode },
    { import = "plugins.formatting", cond = not vim.g.vscode },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = true,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },

  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates

  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        -- 不用 .editorconfig 规则时可关
        "editorconfig",

        -- 不直接打开 .gz / .zip / .tar 文件时可关
        "gzip",
        "tarPlugin",
        "zipPlugin",

        -- 不用 :Man 时可关
        "man",

        -- 不常用 % 在 if/endif、html tag 等结构间跳转时可关
        -- "matchit",

        -- 不需要高亮配对括号时可关
        -- "matchparen",

        -- 已禁用 netrw / 不用内置目录浏览
        "netrwPlugin",

        -- 不需要 OSC52 终端剪贴板时可关
        "osc52",

        -- 不自动下载缺失 spellfile 时可关
        "spellfile",

        -- 不用内置教程
        "tutor",

        -- tohtml 本来就不是默认加载，关不关都影响很小
        "tohtml",

        -- 使用非纯 lua 插件需要 / 按需启动 remote hosts
        -- "rplugin",

        -- 跨会话保存 marks / history / registers
        -- "shada",
      },
    },
  },
})
