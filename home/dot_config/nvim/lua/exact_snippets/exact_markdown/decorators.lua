local ls = require("luasnip")
local s = ls.snippet
local f = ls.function_node
local parse = ls.parser.parse_snippet

local h = require("snippets.helpers")
local context = require("snippets.context")

local math_auto = h.math_auto

return {
  -- 〖饰品装饰正则〗
  s(
    {
      trig = "([a-zA-Z])hat",
      regTrig = true,
      snippetType = "autosnippet",
    },
    f(function(_, snip)
      return "\\hat{" .. snip.captures[1] .. "}"
    end),
    { condition = context.in_mathzone }
  ),

  s(
    {
      trig = "([a-zA-Z])bar",
      regTrig = true,
      snippetType = "autosnippet",
    },
    f(function(_, snip)
      return "\\bar{" .. snip.captures[1] .. "}"
    end),
    { condition = context.in_mathzone }
  ),

  s(
    {
      trig = "([a-zA-Z])vec",
      regTrig = true,
      snippetType = "autosnippet",
    },
    f(function(_, snip)
      return "\\vec{" .. snip.captures[1] .. "}"
    end),
    { condition = context.in_mathzone }
  ),

  s(
    {
      trig = "([a-zA-Z])tilde",
      regTrig = true,
      snippetType = "autosnippet",
    },
    f(function(_, snip)
      return "\\tilde{" .. snip.captures[1] .. "}"
    end),
    { condition = context.in_mathzone }
  ),

  s(
    {
      trig = "([a-zA-Z])dot",
      regTrig = true,
      snippetType = "autosnippet",
      priority = 900,
    },
    f(function(_, snip)
      return "\\dot{" .. snip.captures[1] .. "}"
    end),
    { condition = context.in_mathzone }
  ),

  s(
    {
      trig = "([a-zA-Z])ddot",
      regTrig = true,
      snippetType = "autosnippet",
      priority = 1100,
    },
    f(function(_, snip)
      return "\\ddot{" .. snip.captures[1] .. "}"
    end),
    { condition = context.in_mathzone }
  ),

  s(
    {
      trig = "([a-zA-Z])und",
      regTrig = true,
      snippetType = "autosnippet",
    },
    f(function(_, snip)
      return "\\underline{" .. snip.captures[1] .. "}"
    end),
    { condition = context.in_mathzone }
  ),

  -- 〖饰品手动输入〗
  math_auto("hat", "\\hat{$0}$1"),
  math_auto("bar", "\\bar{$0}$1"),
  math_auto("dot", "\\dot{$0}$1", 900),
  math_auto("ddot", "\\ddot{$0}$1"),
  math_auto("tilde", "\\tilde{$0}$1"),
  math_auto("vec", "\\vec{$0}$1"),
  math_auto("und", "\\underline{$0}$1"),
  math_auto("cdot", "\\cdot"),

  -- 〖可视化包裹操作〗
  s({
    trig = "U",
    snippetType = "autosnippet",
  }, parse("", "\\underbrace{ ${TM_SELECTED_TEXT} }_{ $0 }"), { condition = context.in_mathzone }),

  s({
    trig = "O",
    snippetType = "autosnippet",
  }, parse("", "\\overbrace{ ${TM_SELECTED_TEXT} }^{ $0 }"), { condition = context.in_mathzone }),

  s({
    trig = "S",
    snippetType = "autosnippet",
  }, parse("", "\\sqrt{ ${TM_SELECTED_TEXT} }"), { condition = context.in_mathzone }),

  -- 〖括号补全〗
  math_auto("avg", "\\langle $0 \\rangle $1"),
  math_auto("lr(", "\\left( $0 \\right) $1"),
  math_auto("lr{", "\\left\\{ $0 \\right\\} $1"),
  math_auto("lr[", "\\left[ $0 \\right] $1"),
  math_auto("lr|", "\\left| $0 \\right| $1"),
}
