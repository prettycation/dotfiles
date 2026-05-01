return {
  -- CodeDiff 配置
  {
    "esmuellert/codediff.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
    },
    cmd = "CodeDiff",

    -- 界面启动快捷键
    keys = {
      { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "CodeDiff: Diff Explorer", noremap = true, silent = true },
      { "<leader>gf", "<cmd>CodeDiff file HEAD<cr>", desc = "CodeDiff: Diff File HEAD", noremap = true, silent = true },
      {
        "<leader>gh",
        "<cmd>CodeDiff history<cr>",
        desc = "CodeDiff: Diff File History",
        noremap = true,
        silent = true,
      },
    },

    opts = {
      -- 高亮自动适配
      highlights = {
        line_insert = nil,
        line_delete = nil,
        char_insert = nil,
        char_delete = nil,
        char_brightness = nil,
      },
      -- VSCode 风格侧边栏
      explorer = {
        position = "left",
        width = 30,
        view_mode = "tree",
        icons = { folder_closed = "", folder_open = "" },
      },
      diff = {
        disable_inlay_hints = true,
        original_position = "left",
        -- 开启解决冲突时的三栏视图（左：Incoming历史，中：Result最终修改，右：Current目前）
        conflict_result_position = "center",
      },
      -- 内部快捷键
      keymaps = {
        view = {
          quit = "q",
          next_hunk = "]c",
          prev_hunk = "[c",
          diff_get = "do",
          diff_put = "dp",
          toggle_stage = "-",
          toggle_explorer = "<leader>b",
        },
      },
    },

    -- 使用 config 替代原本的 init，一方面传入 opts，另一方面解决顶栏出现多个奇怪 Buffer 的 Bug
    config = function(_, opts)
      require("codediff").setup(opts)

      -- 在 Tab 关闭时清理残留的 [No Name] 空 Buffer，解决 bufferline 上的多余标签问题
      vim.api.nvim_create_autocmd("TabClosed", {
        group = vim.api.nvim_create_augroup("CodeDiffTabCleanUp", { clear = true }),
        callback = function()
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            -- 确保 Buffer 仍合法且已加载
            if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
              local name = vim.api.nvim_buf_get_name(bufnr)
              local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })

              -- 如果它是一个未修改的空文件/无名文件
              if name == "" and buftype == "" then
                local is_modified = vim.api.nvim_get_option_value("modified", { buf = bufnr })
                if not is_modified then
                  local line_count = vim.api.nvim_buf_line_count(bufnr)
                  local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""

                  -- 判断它是否真的空无一字，且当前没有在任何窗口中显示
                  if line_count <= 1 and first_line == "" then
                    local windows = vim.fn.win_findbuf(bufnr)
                    if #windows == 0 then
                      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
                    end
                  end
                end
              end
            end
          end
        end,
      })
    end,
  },
}
