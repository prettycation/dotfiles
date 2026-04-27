local ls = require("luasnip")
local s = ls.snippet
local f = ls.function_node

local h = require("snippets.helpers")
local context = require("snippets.context")

local math_auto = h.math_auto

return {
  -- 〖自动下标逻辑〗
  -- x1 -> x_1
  s(
    {
      trig = "([A-Za-z])(%d)",
      regTrig = true,
      snippetType = "autosnippet",
      priority = 800,
    },
    f(function(_, snip)
      return snip.captures[1] .. "_{" .. snip.captures[2] .. "}"
    end),
    { condition = context.in_mathzone }
  ),

  -- 〖符号〗
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
}
