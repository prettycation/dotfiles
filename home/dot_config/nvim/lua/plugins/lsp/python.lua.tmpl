return {
  -- LSP Server
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- 禁用 pyright
        pyright = {
          enabled = false,
        },

        -- 启用 basedpyright
        basedpyright = {
          enabled = true,
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
              },
            },
          },
        },
      },
    },
  },

  -- Mason (自动安装/卸载)
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      -- 从安装列表中移除 pyright
      for i, tool in ipairs(opts.ensure_installed) do
        if tool == "pyright" then
          table.remove(opts.ensure_installed, i)
          break
        end
      end

      -- 确保安装 basedpyright
      if not vim.tbl_contains(opts.ensure_installed, "basedpyright") then
        table.insert(opts.ensure_installed, "basedpyright")
      end
    end,
  },
}
