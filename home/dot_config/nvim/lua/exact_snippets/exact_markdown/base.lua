local h = require("snippets.helpers")
local auto = h.auto
local math_auto = h.math_auto

-- ==========================================
-- 基础 Snippets 列表
-- ==========================================
return {
  -- 〖基础触发〗
  auto(";d", "$"),
  auto("mk", "$$0$"),
  auto("dm", "$$\n$0\n$$"),

  -- 〖数学基础〗
  math_auto("beg", "\\begin{$1}\n$0\n\\end{$1}"),
  math_auto("ds", "\\displaystyle "),
  math_auto("text", "\\text{$0}$1"),
  math_auto('"', "\\text{$0}$1"),
  math_auto("//", "\\dfrac{$1}{$2}$0"),

  -- 〖基本运算〗
  math_auto("sr", "^{2}"),
  math_auto("cb", "^{3}"),
  math_auto("rd", "^{$0}$1"),
  math_auto("_", "_{$0}$1"),
  math_auto("sts", "_\\text{$0}"),
  math_auto("sq", "\\sqrt{ $0 }$1"),
  math_auto("ee", "e^{ $0 }$1"),
  math_auto("invs", "^{-1}"),
  math_auto("conj", "^{*}"),
  math_auto("Re", "\\mathrm{Re}"),
  math_auto("Im", "\\mathrm{Im}"),
  math_auto("bf", "\\mathbf{$0}"),
  math_auto("rm", "\\mathrm{$0}$1"),
  math_auto("trace", "\\mathrm{Tr}"),
}
