return {
  {
    "gbprod/cutlass.nvim",
    -- 在 vscode 中加载
    cond = true,
    lazy = true,
    keys = {
      "d",
      "x",
      "s",
      "c",
      "m",
      "v",
      -- 这些键触发加载
    },
    opts = {
      -- “剪切”键。
      cut_key = "m",

      -- 覆盖默认的删除操作（d, c, s 等）为黑洞操作
      override_del = true,

      -- 这里定义哪些键会被“修改”为不走剪贴板
      exclude = {},

      -- 将这些操作重定向到黑洞寄存器 "_"
      registers = {
        select = "_",
        delete = "_",
        change = "_",
      },
    },
  },
}
