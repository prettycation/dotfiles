# -----------------------------------------------------------------------------
# 60-completion.nu
# -----------------------------------------------------------------------------

# -----------------------------
# external completer: carapace
# -----------------------------
let carapace_completer = {|spans|
  if (($spans | length) == 0) {
    null
  } else if ((which carapace | length) == 0) {
    null
  } else {
    try {
      carapace $spans.0 nushell ...$spans | from json
    } catch {
      null
    }
  }
}

$env.config.completions = (
  $env.config.completions
  | merge {
      external: {
        enable: true
        max_results: 200
        completer: $carapace_completer
      }
    }
)
