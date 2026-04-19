return {
  {
    "catppuccin/nvim",
    lazy = false,
    priority = 1000,
    name = "catppuccin",
    opts = function(_, opts)
      -- opts.transparent_background = true
      opts.flavour = "mocha"

      opts.integrations = opts.integrations or {}
      opts.integrations.flash = false
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-nvim",
    },
  },
}
