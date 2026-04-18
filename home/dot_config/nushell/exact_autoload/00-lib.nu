use std/util "path add"

def has [cmd: string] {
  (which $cmd | length) > 0
}

def --env prepend-paths-if-exist [dirs: list<string>] {
  let existing = (
    $dirs
    | each {|d| $d | path expand }
    | where {|p| $p | path exists }
  )

  if (($existing | length) > 0) {
    $env.PATH = ([$existing, ($env.PATH? | default [])] | flatten | uniq)
  }
}
