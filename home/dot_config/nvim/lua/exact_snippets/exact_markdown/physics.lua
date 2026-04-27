local h = require("snippets.helpers")

local math_auto = h.math_auto

return {
  -- 〖物理与量子力学〗
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
}
