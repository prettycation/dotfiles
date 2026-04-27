local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node

local context = require("snippets.context")

-- ==========================================
-- 动态逻辑实现 (矩阵与分数)
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
    table.insert(res, " " .. line)
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

return {
  -- 〖分数逻辑修复: 支持 \infty/ 〗
  s({
    trig = "([%w%.%%\\]+)/",
    regTrig = true,
    snippetType = "autosnippet",
    priority = 1100,
  }, { d(1, frac_gen) }, { condition = context.in_mathzone }),

  -- 〖动态单位矩阵〗
  s({
    trig = "iden(%d)",
    regTrig = true,
    snippetType = "autosnippet",
  }, { d(1, identity_matrix) }, { condition = context.in_mathzone }),
}
