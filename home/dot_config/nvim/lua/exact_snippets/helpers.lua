local ls = require("luasnip")
local parse = ls.parser.parse_snippet
local context = require("snippets.context")

local M = {}

-- ==========================================
-- 构造工厂函数
-- ==========================================
function M.auto(trig, body)
  return parse({ trig = trig, snippetType = "autosnippet" }, body)
end

function M.math_auto(trig, body, priority)
  return parse({
    trig = trig,
    snippetType = "autosnippet",
    wordTrig = false,
    priority = priority or 1000,
    condition = context.in_mathzone,
  }, body)
end

return M
