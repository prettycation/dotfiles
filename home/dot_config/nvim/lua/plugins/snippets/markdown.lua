local ls = require("luasnip")
local s = ls.snippet
local f = ls.function_node
local i = ls.insert_node
local t = ls.text_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local parse = ls.parser.parse_snippet

-- ==========================================
-- 1. 数学模式检测 (针对注入环境优化)
-- ==========================================
local function in_mathzone()
  local node = vim.treesitter.get_node({ ignore_injections = false })
  if not node then
    return false
  end
  while node do
    local type = node:type()
    if type == "inline_formula" or type == "math_environment" or type == "latex_block" or type == "math_block" then
      return true
    end
    node = node:parent()
  end
  return false
end

-- ==========================================
-- 2. 动态逻辑实现 (矩阵与分数)
-- ==========================================

-- 单位矩阵生成 iden3 -> 3x3 (使用 Table 处理多行)
local function identity_matrix(args, snip)
  local n = tonumber(snip.captures[1]) or 3
  local res = { "\\begin{pmatrix}" }
  for r = 1, n do
    local line = ""
    for c = 1, n do
      line = line .. (r == c and "1" or "0")
      if c < n then
        line = line .. " & "
      end
    end
    if r < n then
      line = line .. " \\\\"
    end
    table.insert(res, "  " .. line)
  end
  table.insert(res, "\\end{pmatrix}")
  return sn(nil, { t(res) })
end

-- 自动分数逻辑: 1/ -> \dfrac{1}{ } (支持 \infty/)
local function frac_gen(_, snip)
  return sn(nil, {
    t("\\dfrac{"),
    t(snip.captures[1]),
    t("}{"),
    i(1),
    t("}"),
    i(0),
  })
end

-- ==========================================
-- 3. 构造工厂函数
-- ==========================================
local function auto(trig, body)
  return parse({ trig = trig, snippetType = "autosnippet" }, body)
end

local function math_auto(trig, body, priority)
  return parse({
    trig = trig,
    snippetType = "autosnippet",
    wordTrig = false,
    priority = priority or 1000,
    condition = in_mathzone,
  }, body)
end

-- ==========================================
-- 4. 基础 Snippets 列表
-- ==========================================
local snippets = {
  -- 【基础触发】
  auto(";d", "$"),
  auto("mk", "$$0$"),
  auto("dm", "$$\n$0\n$$"),

  -- 【数学基础】
  math_auto("beg", "\\begin{$1}\n$0\n\\end{$1}"),
  math_auto("ds", "\\displaystyle "),
  math_auto("text", "\\text{$0}$1"),
  math_auto('"', "\\text{$0}$1"),
  math_auto("//", "\\dfrac{$1}{$2}$0"),

  -- 【分数逻辑修复: 支持 \infty/ 】
  s(
    { trig = "([%w%.%%\\]+)/", regTrig = true, snippetType = "autosnippet", priority = 1100 },
    { d(1, frac_gen) },
    { condition = in_mathzone }
  ),

  -- 【基本运算】
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

  -- 【希腊字母快捷键】
  math_auto("@a", "\\alpha"),
  math_auto("@b", "\\beta"),
  math_auto("@g", "\\gamma"),
  math_auto("@G", "\\Gamma"),
  math_auto("@d", "\\delta"),
  math_auto("@D", "\\Delta"),
  math_auto("@e", "\\epsilon"),
  math_auto(":e", "\\varepsilon"),
  math_auto("@z", "\\zeta"),
  math_auto("@t", "\\theta"),
  math_auto("@T", "\\Theta"),
  math_auto(":t", "\\vartheta"),
  math_auto("@i", "\\iota"),
  math_auto("@k", "\\kappa"),
  math_auto("@l", "\\lambda"),
  math_auto("@L", "\\Lambda"),
  math_auto("@s", "\\sigma"),
  math_auto("@S", "\\Sigma"),
  math_auto("@u", "\\upsilon"),
  math_auto("@U", "\\Upsilon"),
  math_auto("@o", "\\omega"),
  math_auto("@O", "\\Omega"),
  math_auto("ome", "\\omega"),
  math_auto("Ome", "\\Omega"),

  -- 【饰品装饰正则】
  s(
    { trig = "([a-zA-Z])hat", regTrig = true, snippetType = "autosnippet" },
    f(function(_, snip)
      return "\\hat{" .. snip.captures[1] .. "}"
    end),
    { condition = in_mathzone }
  ),
  s(
    { trig = "([a-zA-Z])bar", regTrig = true, snippetType = "autosnippet" },
    f(function(_, snip)
      return "\\bar{" .. snip.captures[1] .. "}"
    end),
    { condition = in_mathzone }
  ),
  s(
    { trig = "([a-zA-Z])vec", regTrig = true, snippetType = "autosnippet" },
    f(function(_, snip)
      return "\\vec{" .. snip.captures[1] .. "}"
    end),
    { condition = in_mathzone }
  ),
  s(
    { trig = "([a-zA-Z])tilde", regTrig = true, snippetType = "autosnippet" },
    f(function(_, snip)
      return "\\tilde{" .. snip.captures[1] .. "}"
    end),
    { condition = in_mathzone }
  ),
  s(
    { trig = "([a-zA-Z])dot", regTrig = true, snippetType = "autosnippet", priority = 900 },
    f(function(_, snip)
      return "\\dot{" .. snip.captures[1] .. "}"
    end),
    { condition = in_mathzone }
  ),
  s(
    { trig = "([a-zA-Z])ddot", regTrig = true, snippetType = "autosnippet", priority = 1100 },
    f(function(_, snip)
      return "\\ddot{" .. snip.captures[1] .. "}"
    end),
    { condition = in_mathzone }
  ),
  s(
    { trig = "([a-zA-Z])und", regTrig = true, snippetType = "autosnippet" },
    f(function(_, snip)
      return "\\underline{" .. snip.captures[1] .. "}"
    end),
    { condition = in_mathzone }
  ),

  -- 【饰品手动输入】
  math_auto("hat", "\\hat{$0}$1"),
  math_auto("bar", "\\bar{$0}$1"),
  math_auto("dot", "\\dot{$0}$1", 900),
  math_auto("ddot", "\\ddot{$0}$1"),
  math_auto("tilde", "\\tilde{$0}$1"),
  math_auto("vec", "\\vec{$0}$1"),
  math_auto("und", "\\underline{$0}$1"),
  math_auto("cdot", "\\cdot"),

  -- 【自动下标逻辑】
  -- x1 -> x_1
  s(
    { trig = "([A-Za-z])(%d)", regTrig = true, snippetType = "autosnippet", priority = 800 },
    f(function(_, snip)
      return snip.captures[1] .. "_{" .. snip.captures[2] .. "}"
    end),
    { condition = in_mathzone }
  ),

  -- 【符号】
  math_auto("ooo", "\\infty"),
  math_auto("sum", "\\sum_{${1:i}=${2:1}}^{${3:N}} $0"),
  math_auto("prod", "\\prod_{${1:i}=${2:1}}^{${3:N}} $0"),
  math_auto("lim", "\\lim_{ ${1:n} \\to ${2:\\infty} } $0"),
  math_auto("+-", "\\pm"),
  math_auto("-+", "\\mp"),
  math_auto("...", "\\dots"),
  math_auto("nabl", "\\nabla"),
  math_auto("del", "\\nabla"),
  math_auto("xx", "\\times"),
  math_auto("**", "\\cdot"),
  math_auto("===", "\\equiv"),
  math_auto("!=", "\\neq"),
  math_auto(">=", "\\geq"),
  math_auto("<=", "\\leq"),
  math_auto(">>", "\\gg"),
  math_auto("<<", "\\ll"),
  math_auto("simm", "\\sim"),
  math_auto("sim=", "\\simeq"),
  math_auto("prop", "\\propto"),

  -- 【箭头】
  math_auto("<->", "\\leftrightarrow "),
  math_auto("->", "\\to"),
  math_auto("!>", "\\mapsto"),
  math_auto("=>", "\\implies"),
  math_auto("=<", "\\impliedby"),

  -- 【集合与数学字体】
  math_auto("and", "\\cap"),
  math_auto("orr", "\\cup"),
  math_auto("inn", "\\in"),
  math_auto("notin", "\\not\\in"),
  math_auto("\\\\\\", "\\setminus"),
  math_auto("sub=", "\\subseteq"),
  math_auto("sup=", "\\supseteq"),
  math_auto("eset", "\\emptyset"),
  math_auto("set", "\\{ $0 \\}$1"),
  math_auto("exists", "\\exists"),
  math_auto("LL", "\\mathcal{L}"),
  math_auto("HH", "\\mathcal{H}"),
  math_auto("CC", "\\mathbb{C}"),
  math_auto("RR", "\\mathbb{R}"),
  math_auto("ZZ", "\\mathbb{Z}"),
  math_auto("NN", "\\mathbb{N}"),

  -- 【微分与积分】
  math_auto("ddt", "\\frac{d}{dt} "),
  s(
    { trig = "par", snippetType = "autosnippet" },
    parse("", "\\frac{ \\partial ${0:y} }{ \\partial ${1:x} } $2"),
    { condition = in_mathzone }
  ),
  s(
    { trig = "pa([A-Za-z])([A-Za-z])", regTrig = true, snippetType = "autosnippet" },
    f(function(_, snip)
      return "\\frac{ \\partial " .. snip.captures[1] .. " }{ \\partial " .. snip.captures[2] .. " } "
    end),
    { condition = in_mathzone }
  ),
  math_auto("dint", "\\int_{${0:0}}^{${1:1}} $2 \\, d${3:x} $4"),
  math_auto("oint", "\\oint"),
  math_auto("iint", "\\iint"),
  math_auto("iiint", "\\iiint"),
  math_auto("oinf", "\\int_{0}^{\\infty} $0 \\, d${1:x} $2"),
  math_auto("infi", "\\int_{-\\infty}^{\\infty} $0 \\, d${1:x} $2"),

  -- 【可视化包裹操作】
  s(
    { trig = "U", snippetType = "autosnippet" },
    parse("", "\\underbrace{ ${TM_SELECTED_TEXT} }_{ $0 }"),
    { condition = in_mathzone }
  ),
  s(
    { trig = "O", snippetType = "autosnippet" },
    parse("", "\\overbrace{ ${TM_SELECTED_TEXT} }^{ $0 }"),
    { condition = in_mathzone }
  ),
  s(
    { trig = "S", snippetType = "autosnippet" },
    parse("", "\\sqrt{ ${TM_SELECTED_TEXT} }"),
    { condition = in_mathzone }
  ),

  -- 【物理与量子力学】
  math_auto("kbt", "k_{B}T"),
  math_auto("msun", "M_{\\odot}"),
  math_auto("dag", "^{\\dagger}"),
  math_auto("o+", "\\oplus "),
  math_auto("ox", "\\otimes "),
  math_auto("bra", "\\bra{$0} $1"),
  math_auto("ket", "\\ket{$0} $1"),
  math_auto("brk", "\\braket{ $0 | $1 } $2"),
  math_auto("pu", "\\pu{ $0 }"),
  math_auto("cee", "\\ce{ $0 }"),

  -- 【环境 (修复换行报错)】
  s(
    { trig = "pmat", snippetType = "autosnippet" },
    { t("\\begin{pmatrix}"), i(1), t({ "", "\\end{pmatrix}" }) },
    { condition = in_mathzone }
  ),
  s(
    { trig = "bmat", snippetType = "autosnippet" },
    { t("\\begin{bmatrix}"), i(1), t({ "", "\\end{bmatrix}" }) },
    { condition = in_mathzone }
  ),
  s(
    { trig = "cases", snippetType = "autosnippet" },
    { t("\\begin{cases}"), i(1), t({ "", "\\end{cases}" }) },
    { condition = in_mathzone }
  ),
  s(
    { trig = "align", snippetType = "autosnippet" },
    { t("\\begin{align}"), i(1), t({ "", "\\end{align}" }) },
    { condition = in_mathzone }
  ),

  -- 【动态单位矩阵】
  s(
    { trig = "iden(%d)", regTrig = true, snippetType = "autosnippet" },
    { d(1, identity_matrix) },
    { condition = in_mathzone }
  ),

  -- 【括号补全】
  math_auto("avg", "\\langle $0 \\rangle $1"),
  math_auto("lr(", "\\left( $0 \\right) $1"),
  math_auto("lr{", "\\left\\{ $0 \\right\\} $1"),
  math_auto("lr[", "\\left[ $0 \\right] $1"),
  math_auto("lr|", "\\left| $0 \\right| $1"),

  -- 泰勒展开
  math_auto(
    "tayl",
    "${0:f}(${1:x} + ${2:h}) = ${0:f}(${1:x}) + ${0:f}'(${1:x})${2:h} + ${0:f}''(${1:x}) \\frac{${2:h}^{2}}{2!} + \\dots$3"
  ),
}

-- ==========================================
-- 5. 自动单词补全 (sin -> \sin, alpha -> \alpha)
-- ==========================================
local math_functions = {
  "sin",
  "cos",
  "tan",
  "exp",
  "log",
  "ln",
  "arcsin",
  "arccos",
  "arctan",
  "det",
  "sinh",
  "cosh",
  "tanh",
}
local greek_letters = {
  "alpha",
  "beta",
  "gamma",
  "delta",
  "epsilon",
  "zeta",
  "eta",
  "theta",
  "iota",
  "kappa",
  "lambda",
  "mu",
  "nu",
  "xi",
  "pi",
  "rho",
  "sigma",
  "tau",
  "upsilon",
  "phi",
  "chi",
  "psi",
  "omega",
}

for _, func in ipairs(math_functions) do
  table.insert(snippets, math_auto(func, "\\" .. func))
end

for _, letter in ipairs(greek_letters) do
  table.insert(snippets, math_auto(letter, "\\" .. letter))
end

-- ==========================================
-- 6. 注册与导出
-- ==========================================
ls.add_snippets("markdown", snippets)

return { in_mathzone = in_mathzone }
