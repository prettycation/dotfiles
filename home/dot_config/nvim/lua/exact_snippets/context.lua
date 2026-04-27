local M = {}

-- ==========================================
-- 数学模式检测 (针对注入环境优化)
-- ==========================================
function M.in_mathzone()
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

return M
