return {
  {
    "lewis6991/gitsigns.nvim",
    optional = true,
    opts = function(_, opts)
      opts.signs = vim.tbl_deep_extend("force", opts.signs or {}, {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "│" },
        untracked = { text = "┆" },
      })

      opts.signs_staged = vim.tbl_deep_extend("force", opts.signs_staged or {}, {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "│" },
      })

      local on_attach = opts.on_attach

      opts.on_attach = function(bufnr)
        if on_attach then
          on_attach(bufnr)
        end

        local gitsigns = require("gitsigns")

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = bufnr,
            silent = true,
            desc = desc,
          })
        end

        map("n", "<leader>ghq", gitsigns.setqflist, "Hunks to Quickfix")

        map("n", "<leader>ghQ", function()
          gitsigns.setqflist("all")
        end, "Hunks to Quickfix (All)")

        map("n", "<leader>ghw", gitsigns.toggle_word_diff, "Toggle Word Diff")

        map("n", "<leader>ghl", gitsigns.toggle_current_line_blame, "Toggle Line Blame")
      end
    end,
  },
}
