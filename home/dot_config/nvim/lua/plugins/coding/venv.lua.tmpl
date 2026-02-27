return {
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
      "mfussenegger/nvim-dap-python",
    },
    lazy = false,
    ft = "python",

    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    },

    opts = function(_, opts)
      -- 基础配置
      opts.options = opts.options or {}
      opts.options.debug = false
      opts.options.notify_user_on_venv_activation = true

      -- 环境名称显示
      opts.options.on_telescope_result_callback = function(filename)
        -- 统一路径分隔符，防止 Windows 反斜杠干扰
        filename = filename:gsub("\\", "/")

        -- 获取 python.exe 所在的目录 (通常是 Scripts)
        local parent_path = vim.fn.fnamemodify(filename, ":h")
        local parent_dir = vim.fn.fnamemodify(parent_path, ":t")

        -- 如果是 Scripts 或 bin，往上一层
        if parent_dir == "Scripts" or parent_dir == "bin" then
          local grand_parent_path = vim.fn.fnamemodify(parent_path, ":h")
          local env_name = vim.fn.fnamemodify(grand_parent_path, ":t")

          -- UV 的 .venv 显示项目名
          if env_name == ".venv" then
            local project_path = vim.fn.fnamemodify(grand_parent_path, ":h")
            local project_name = vim.fn.fnamemodify(project_path, ":t")
            return project_name .. " (uv)"
          end

          return env_name -- 返回 Poetry 的 "project-hash" 或普通 venv 名字
        end

        -- 如果是 Anaconda (结构是 envs/name/python.exe)，直接返回 name
        return parent_dir
      end

      -- 平台特定逻辑
      if vim.fn.has("win32") == 1 then
        --  Windows 配置

        -- 清空 LazyVim 默认策略
        opts.search = {}

        -- 注入 Anaconda 策略
        opts.search.anaconda_envs = {
          command = "fd -u -F python.exe E:\\anaconda\\envs --max-depth 2 --full-path --color never -E Lib",
          type = "anaconda",
        }

        opts.search.anaconda_base = {
          command = "fd -u -F python.exe E:\\anaconda --max-depth 1 --full-path --color never -E Lib",
          type = "anaconda",
        }
      else
        -- Linux 配置默认
      end
    end,
  },
}
