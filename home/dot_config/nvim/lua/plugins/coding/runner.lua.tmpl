return {
  -- 1. Code Runner: 负责运行整个文件
  {
    "CRAG666/code_runner.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
    keys = {
      { "<leader>rr", "<cmd>RunCode<cr>", desc = "Run File" },
      { "<leader>rc", "<cmd>RunClose<cr>", desc = "Close Runner" },
    },
    opts = {
      mode = "float",
      float = {
        border = "rounded",
        height = 0.8,
        width = 0.8,
        x = 0.5,
        y = 0.5,
      },
      filetype = {
        python = "python -u",
        typst = "typst compile",
        rust = "cd $dir && rustc $fileName && $dir/$fileNameWithoutExt",
        lua = "lua",
      },
    },
  },

  -- 2. Iron.nvim: 交互式 REPL (Windows 适配版)
  {
    "Vigemus/iron.nvim",
    main = "iron.core",
    opts = function()
      local view = require("iron.view")
      local common = require("iron.fts.common")

      return {
        config = {
          -- 窗口配置：垂直分屏，占据 40% 宽度
          repl_open_cmd = view.split.vertical.botright(0.4),

          -- 语言定义
          repl_definition = {
            python = {
              command = { "python" },
              format = common.bracketed_paste_python,
            },
            lua = {
              command = { "lua" },
            },
            sh = {
              command = { "powershell" },
            },
          },
        },

        -- 键位映射
        -- 注意：我们移除了 clear 和 exit，改在下方的 keys 中自定义实现
        keymaps = {
          toggle_repl = "<leader>ro",
          visual_send = "<leader>rs",
          send_line = "<leader>rs",
          interrupt = "<leader>ri", -- 中断运行 (Ctrl+C)
          restart_repl = "<leader>rR", -- 重启 REPL
        },

        highlight = {
          italic = true,
        },
      }
    end,
    -- 自定义按键绑定 (完美解决 Windows 兼容性问题)
    keys = {
      { "<leader>ro", desc = "Toggle REPL" },
      { "<leader>rs", mode = { "n", "v" }, desc = "Send to REPL" },
      { "<leader>ri", desc = "Interrupt REPL" },
      { "<leader>rR", desc = "Restart REPL" },

      -- 【Windows 修复】自定义清屏：发送 Python 的 os.system('cls')
      {
        "<leader>rl",
        function()
          require("iron.core").send(nil, "import os; os.system('cls')")
        end,
        desc = "Clear REPL",
      },

      -- 【Windows 修复】自定义退出：发送 exit() 并关闭窗口
      {
        "<leader>rq",
        function()
          require("iron.core").send(nil, "exit()")
          -- 延迟 200ms 关闭窗口，给 Python 一点时间退出
          vim.defer_fn(function()
            require("iron.core").close_repl()
          end, 200)
        end,
        desc = "Quit REPL",
      },
    },
  },

  -- 3. 配置 WhichKey 菜单
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>r", group = "run", icon = " " },
      },
    },
  },
}
