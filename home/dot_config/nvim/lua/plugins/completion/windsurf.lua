return {
  {
    "Exafunction/windsurf.nvim",
    name = "windsurf.nvim",
    event = "InsertEnter",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      -- Windsurf / Codeium 初始化。

      -- 1. enable_cmp_source = false
      --    不让 Windsurf 直接走自己的 cmp source，
      --    统一交给 blink.cmp 接入 provider。

      -- 2. virtual_text 保留
      --    即使补全菜单是 blink.cmp 负责，行内 AI 建议仍然由 Windsurf 提供。
      require("codeium").setup({
        enable_cmp_source = false,
        virtual_text = {
          enabled = true,
          key_bindings = {
            accept = "<A-a>",
            next = "<A-n>",
            prev = "<A-p>",
          },
        },
      })

      -- 让 AI 建议高亮更克制一点，复用 Comment 风格。
      vim.api.nvim_set_hl(0, "CodeiumSuggestion", { link = "Comment", force = true })
    end,
  },
}
