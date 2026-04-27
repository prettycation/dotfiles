local is_vscode = vim.g.vscode

local imports = {

  -- Custom plugin specs
  { import = "plugins" },
  { import = "plugins.lsp", cond = not is_vscode },
  { import = "plugins.lang", cond = not is_vscode },
  { import = "plugins.ai", cond = not is_vscode },
  { import = "plugins.git", cond = not is_vscode },
  { import = "plugins.coding", cond = not is_vscode },
  { import = "plugins.editor" },
  { import = "plugins.completion", cond = not is_vscode },
  { import = "plugins.preview", cond = not is_vscode },
  { import = "plugins.formatting", cond = not is_vscode },
}

return imports
