local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node

local context = require("snippets.context")

return {
  -- 〖环境〗
  s({
    trig = "pmat",
    snippetType = "autosnippet",
  }, {
    t("\\begin{pmatrix}"),
    i(1),
    t({ "", "\\end{pmatrix}" }),
  }, { condition = context.in_mathzone }),

  s({
    trig = "bmat",
    snippetType = "autosnippet",
  }, {
    t("\\begin{bmatrix}"),
    i(1),
    t({ "", "\\end{bmatrix}" }),
  }, { condition = context.in_mathzone }),

  s({
    trig = "cases",
    snippetType = "autosnippet",
  }, {
    t("\\begin{cases}"),
    i(1),
    t({ "", "\\end{cases}" }),
  }, { condition = context.in_mathzone }),

  s({
    trig = "align",
    snippetType = "autosnippet",
  }, {
    t("\\begin{align}"),
    i(1),
    t({ "", "\\end{align}" }),
  }, { condition = context.in_mathzone }),
}
