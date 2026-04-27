local h = require("snippets.helpers")

local math_auto = h.math_auto

local snippets = {}

-- ==========================================
-- 自动单词补全 (sin -> \sin, alpha -> \alpha)
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

return snippets
