return {
  {
    "L3MON4D3/LuaSnip",
    cond = not vim.g.vscode,
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts = function()
      -- 开启自动展开和文本改变时更新
      return {
        enable_autosnippets = true,
        update_events = "TextChanged,TextChangedI",
      }
    end,
    config = function(_, opts)
      -- 应用 opts 设置
      require("luasnip").setup(opts)

      -- 加载 Vscode-like snippet
      require("luasnip.loaders.from_vscode").lazy_load()

      -- 加载自定义 snippets
      require("snippets.markdown").setup()
    end,
  },
}
