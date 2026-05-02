return {
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sections.lualine_z = {
        {
          "encoding",
          fmt = function(str)
            return str .. (vim.bo.bomb and " BOM" or "")
          end,
        },
      }
    end,
  },
}
