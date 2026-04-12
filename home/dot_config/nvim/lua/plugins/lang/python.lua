return {
  -- LSP Server
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.basedpyright = opts.servers.basedpyright or {}
      opts.servers.basedpyright.settings = opts.servers.basedpyright.settings or {}
      opts.servers.basedpyright.settings.basedpyright = opts.servers.basedpyright.settings.basedpyright or {}

      -- 1. 保留 LazyVim / 其他插件已有的 basedpyright 配置；
      -- 2. 只覆盖下面列出的 analysis 字段；
      opts.servers.basedpyright.settings.basedpyright.analysis =
        vim.tbl_deep_extend("force", opts.servers.basedpyright.settings.basedpyright.analysis or {}, {
          -- 类型检查级别

          -- "off" / "basic" / "standard" / "strict" / "recommended" / "all"

          -- 推荐将这个选项设置到 pyproject.toml / pyrightconfig.json 里，
          -- 这样 CLI 和 LSP 行为会一致。
          typeCheckingMode = "basic",

          -- 自动搜索常见源码路径

          -- 当项目里没有显式定义 execution environments 时，
          -- basedpyright 会自动把像 "src" 这样的常见目录加入搜索路径。

          autoSearchPaths = true,

          -- 在没有类型 stub 时，允许读取第三方库源码推断类型

          -- 开启后，basedpyright 会在缺少 .pyi stub 的情况下，
          -- 直接读取库源码来补充类型信息。

          useLibraryCodeForTypes = true,

          -- 只分析当前打开的文件
          -- CI 可以再改成 "workspace"。
          diagnosticMode = "openFilesOnly",
        })
    end,
  },
}
