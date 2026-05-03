return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      -- "sindrets/diffview.nvim", -- optional - Diff integration
      "esmuellert/codediff.nvim",
      "folke/snacks.nvim", -- optional
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gn", "<cmd>Neogit<cr>", desc = "Git Neogit" },
    },
    opts = {
      signs = {
        item = { "▶", "▼" },
        section = { "▶", "▼" },
      },
    },
  },
}
