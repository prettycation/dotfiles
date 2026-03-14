return {
  {
    "hasser0/mdmath.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    build = ":MdMath build", -- 极其重要：安装后会自动运行 nodejs 编译
    opts = {
      -- 允许的文件类型
      filetypes = { "markdown", "tex" },

      -- 颜色设置：'Normal' 会随你的配色方案自动变化，也可以填十六进制如 '#89b4fa'
      foreground = "Normal",

      -- 插入模式下的显示策略：
      -- "hide_all": 进入插入模式时隐藏所有公式（推荐，防止编辑时闪烁）
      -- "show_all": 始终显示
      insert_strategy = "hide_all",

      -- 普通模式下的显示策略：
      -- "hide_in_line": 隐藏光标所在行的公式，显示其他行（方便修改当前行代码）
      -- "show_all": 全部显示
      normal_strategy = "hide_in_line",

      -- 行内显示策略：
      -- "fixed_size": 图片大小受限于文本区域（较稳定）
      -- "flex_size": 根据图片大小自动伸缩（视觉效果更好，但需 conceallevel >= 1）
      inline_strategy = "fixed_size",

      -- 居中显示独立段落公式 ($$ ... $$)
      center_display = true,

      -- 公式垂直对齐微调 (0.0 到 0.3 之间)
      -- 如果你发现公式偏上或偏下，调整这个值
      bottom_line_ratio = 0.15,

      -- 刷新频率 (毫秒)
      update_interval = 50,

      -- 独立段落公式的缩放倍率
      display_zoom = 1.2,
    },
  },
}
