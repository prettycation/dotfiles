local ls = require("luasnip")
local s = ls.snippet
local f = ls.function_node
local parse = ls.parser.parse_snippet

local h = require("snippets.helpers")
local context = require("snippets.context")

local math_auto = h.math_auto

return {
  -- 〖微分与积分〗
  math_auto("ddt", "\\frac{d}{dt} "),

  s({
    trig = "par",
    snippetType = "autosnippet",
  }, parse("", "\\frac{ \\partial ${0:y} }{ \\partial ${1:x} } $2"), { condition = context.in_mathzone }),

  s(
    {
      trig = "pa([A-Za-z])([A-Za-z])",
      regTrig = true,
      snippetType = "autosnippet",
    },
    f(function(_, snip)
      return "\\frac{ \\partial " .. snip.captures[1] .. " }{ \\partial " .. snip.captures[2] .. " } "
    end),
    { condition = context.in_mathzone }
  ),

  math_auto("dint", "\\int_{${0:0}}^{${1:1}} $2 \\, d${3:x} $4"),
  math_auto("oint", "\\oint"),
  math_auto("iint", "\\iint"),
  math_auto("iiint", "\\iiint"),
  math_auto("oinf", "\\int_{0}^{\\infty} $0 \\, d${1:x} $2"),
  math_auto("infi", "\\int_{-\\infty}^{\\infty} $0 \\, d${1:x} $2"),

  -- 泰勒展开
  math_auto(
    "tayl",
    "${0:f}(${1:x} + ${2:h}) = ${0:f}(${1:x}) + ${0:f}'(${1:x})${2:h} + ${0:f}''(${1:x}) \\frac{${2:h}^{2}}{2!} + \\dots$3"
  ),
}
