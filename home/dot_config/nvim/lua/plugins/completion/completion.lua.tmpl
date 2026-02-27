return {
  -- Windsurf / Codeium
  {
    "Exafunction/windsurf.nvim",
    name = "windsurf.nvim",
    event = "InsertEnter",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "saghen/blink.cmp",
    },
    config = function()
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
      vim.api.nvim_set_hl(0, "CodeiumSuggestion", { link = "Comment", force = true })
    end,
  },

  -- Blink.cmp
  {
    "saghen/blink.cmp",
    dependencies = {
      "windsurf.nvim",
      "rafamadriz/friendly-snippets",
    },
    version = "*",

    opts = {
      -- 大文件或特定文件类型禁用补全
      enabled = function()
        -- 禁止在 Telescope 或 Grug-far 窗口启用（防止冲突）
        local filetype_is_allowed = not vim.tbl_contains({ "grug-far", "TelescopePrompt" }, vim.bo.filetype)

        -- 检测文件大小（1MB）
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(0))
        local filesize_is_allowed = true
        if ok and stats then
          filesize_is_allowed = stats.size < (1024 * 1024) -- 1MB
        end

        -- 只有当不是命令模式时才检查 buffer，命令模式总是允许
        if vim.api.nvim_get_mode().mode == "c" then
          return true
        end

        return filetype_is_allowed and filesize_is_allowed
      end,

      completion = {
        -- 关闭 Blink 的灰字，已有 Codeium 的 virtual_text
        ghost_text = { enabled = false },

        -- 自动补全函数括号
        accept = { auto_brackets = { enabled = true } },

        -- 自动显示文档悬浮窗（延迟 0.2秒，避免晃眼）
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },

        -- 列表行为优化
        list = {
          selection = {
            -- 默认不选中第一项，需要手动按键选
            preselect = false,
            -- 选中的时候预览直接上屏
            auto_insert = true,
          },
        },
      },

      -- 命令行模式补全
      cmdline = {
        completion = {
          menu = { auto_show = true },
        },
        keymap = {
          preset = "none", -- 自定义按键
          ["<Tab>"] = { "show", "accept" }, -- Tab 键接受
          ["<C-k>"] = { "select_prev", "fallback" }, -- 上一个
          ["<C-j>"] = { "select_next", "fallback" }, -- 下一个
        },
      },

      -- 编辑模式快捷键优化
      keymap = {
        preset = "default",

        -- C-k / C-j
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },

        -- 滚动文档
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },

        -- 可以在这里加一个快捷键手动触发 Codeium 面板
      },

      sources = {
        default = { "lsp", "path", "snippets", "buffer", "codeium" },
        providers = {
          codeium = {
            name = "Codeium",
            module = "codeium.blink",
            async = true,
          },
        },
      },
    },
  },
}
