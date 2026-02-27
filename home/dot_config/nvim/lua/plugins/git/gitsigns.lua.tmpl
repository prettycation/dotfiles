return {
  "lewis6991/gitsigns.nvim",
  -- event = { "BufReadPre", "BufNewFile" },
  -- 禁用懒加载：确保 init 中的路径劫持 Hook 在任何 Git 操作前生效
  lazy = false,

  -- 全局路径解析劫持 Hook
  -- 解决 Windows 下使用 Junction 跨盘符链接时，gitsigns 会强制解析物理路径，导致无法识别 F 盘 Git 仓库的问题。
  init = function()
    -- 获取 Libuv 模块 (兼容 Neovim 新旧版本)
    local uv = vim.uv or vim.loop

    -- 保存原始的 fs_realpath 函数，以便对非项目文件使用默认逻辑
    local orig_realpath = uv.fs_realpath

    -- 重写 fs_realpath 函数，植入拦截逻辑
    uv.fs_realpath = function(path)
      -- 如果路径为空，则回退
      if not path then
        return orig_realpath(path)
      end

      -- 将 Windows 反斜杠 \ 统一替换为正斜杠 /
      local normalized_path = path:gsub("\\", "/")

      -- 获取当前工作目录 (CWD) 并规范化
      -- 假设 Neovim 是在项目根目录启动的
      local cwd = uv.cwd()
      local normalized_cwd = cwd and cwd:gsub("\\", "/") or ""

      -- 如果 Neovim 请求的文件路径是以当前项目目录开头的 (即使它实际上是个指向其他盘符的 Junction)
      -- 就认定它属于当前项目，阻止 gitsigns 去解析它的物理真实路径。
      if #normalized_cwd > 0 and normalized_path:find(normalized_cwd, 1, true) then
        -- 计算相对路径
        -- 原理：gitsigns 在 Windows 下有一个 bug/特性：
        -- 如果文件路径不是以 / 开头，它就会认为这是相对路径，
        -- 并将其拼接到 toplevel (Git根目录) 后面。
        -- 利用这一点，如果我们返回一个真正的相对路径 (如 .config/bat/config)，
        -- gitsigns 拼接后就能得到正确的逻辑路径：CWD/.config/bat/config

        -- 从 CWD 长度 + 2 (跳过路径分隔符) 开始截取
        local rel_path = normalized_path:sub(#normalized_cwd + 2)

        -- 边界情况处理
        -- 如果文件正好就是根目录本身 (虽然 fs_realpath 通常针对文件)，
        -- 或者截取后为空，则返回 '.' 代表当前目录，避免传给 Git 空字符串导致报错
        if rel_path == "" then
          return "."
        end

        -- 返回计算出的相对路径，欺骗 gitsigns 完成正确拼接
        return rel_path
      end

      -- 对于项目之外的文件 (如 vim runtime, 插件源码等)，走正常的原生解析逻辑
      return orig_realpath(path)
    end
  end,
  opts = {
    signs = {
      add = { text = "│" },
      change = { text = "│" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "│" },
      untracked = { text = "┆" },
    },

    numhl = false, -- 关闭行号高亮
    linehl = false, -- 关闭背景色
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")
      -- 注册 Group 名称 (Git Signs)
      -- 使用 pcall 防止未安装 which-key 时报错
      pcall(function()
        local wk = require("which-key")
        wk.add({
          { "<leader>h", group = "Git History" },
          { "<leader>t", group = "Toggle/Typst" }, -- 为 tb/tw 注册 Toggle 组
        })
      end)
      -- 辅助函数：支持传入 opts 用于设置 desc
      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end
      -- Navigation (跳转)
      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end, { desc = "Next Hunk" })
      map("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end, { desc = "Prev Hunk" })
      -- Hunk Actions (块操作)
      map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "Preview Hunk" })
      map("n", "<leader>hi", gitsigns.preview_hunk_inline, { desc = "Preview Hunk Inline" })
      map("n", "<leader>hb", function()
        gitsigns.blame_line({ full = true })
      end, { desc = "Blame Line" })
      map("n", "<leader>hd", gitsigns.diffthis, { desc = "Diff This" })
      map("n", "<leader>hD", function()
        gitsigns.diffthis("~")
      end, { desc = "Diff This ~" })
      map("n", "<leader>hQ", function()
        gitsigns.setqflist("all")
      end, { desc = "Set qflist (all)" })

      map("n", "<leader>hq", gitsigns.setqflist, { desc = "Set qflist" })
      -- Toggles (开关)
      map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "Toggle Line Blame" })
      map("n", "<leader>tw", gitsigns.toggle_word_diff, { desc = "Toggle Word Diff" })
      -- Text object (文本对象)
      map({ "o", "x" }, "ih", gitsigns.select_hunk, { desc = "Select Hunk" })
    end,
  },
}
