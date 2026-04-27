local M = {}

local loaded = false

local function extend(target, source)
  vim.list_extend(target, source)
end

-- ==========================================
-- 注册与导出
-- ==========================================
function M.setup()
  if loaded then
    return
  end
  loaded = true

  local ls = require("luasnip")
  local snippets = {}

  extend(snippets, require("snippets.markdown.base"))
  extend(snippets, require("snippets.markdown.operators"))
  extend(snippets, require("snippets.markdown.symbols"))
  extend(snippets, require("snippets.markdown.decorators"))
  extend(snippets, require("snippets.markdown.calculus"))
  extend(snippets, require("snippets.markdown.environments"))
  extend(snippets, require("snippets.markdown.physics"))
  extend(snippets, require("snippets.markdown.dynamic"))
  extend(snippets, require("snippets.markdown.auto_words"))

  ls.add_snippets("markdown", snippets)
end

return M
