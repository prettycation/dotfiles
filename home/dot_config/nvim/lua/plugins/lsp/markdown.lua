return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    optional = true,

    -- extra 会处理 markdown 的基础 filetype。
    -- 使 llm buffer 复用 Markdown 渲染。
    ft = { "markdown", "llm" },

    opts = function(_, opts)
      -- 保留 LazyVim lang.markdown extra 的默认配置，
      opts = opts or {}

      opts.restart_highlighter = true

      -- 标题渲染
      opts.heading = {
        enabled = true,
        sign = false,

        -- overlay: 标题装饰覆盖在文本区域上，而不是额外占列
        position = "overlay", -- inline | overlay

        -- 各级标题图标
        icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },

        -- 如果开启 sign 时使用的符号；这里 sign = false，
        -- 保留它方便以后切换
        signs = { "󰫎 " },

        -- block: 把标题按整块区域来渲染
        width = "block",

        -- 左右 padding / margin 全部压到最小，保持紧凑
        left_margin = 0,
        left_pad = 0,
        right_pad = 0,
        min_width = 0,

        -- 关闭边框相关效果，保持干净简洁
        border = false,
        border_virtual = false,
        border_prefix = false,

        -- 上下边缘装饰字符
        above = "▄",
        below = "▀",

        -- 不额外指定背景高亮，避免和主题打架
        backgrounds = {},

        -- 仅指定前景高亮组，让不同级别标题有自己的颜色
        foregrounds = {
          "RenderMarkdownH1",
          "RenderMarkdownH2",
          "RenderMarkdownH3",
          "RenderMarkdownH4",
          "RenderMarkdownH5",
          "RenderMarkdownH6",
        },
      }

      -- 分隔线（--- / ***）渲染
      opts.dash = {
        enabled = true,
        icon = "─",
        width = 0.5,
        left_margin = 0.5,
        highlight = "RenderMarkdownDash",
      }

      -- 代码块渲染
      opts.code = {
        -- normal: 保持更接近原始文本，不做太重的卡片化修饰
        style = "normal",
      }

      return opts
    end,
  },
}
