return {
  {
    "Kurama622/llm.nvim",
    lazy = true,
    cond = not vim.g.vscode,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    cmd = {
      "LLMAppHandler",
    },
    opts = function()
      local tools = require("llm.tools")

      return {
        url = "https://api.chatanywhere.tech/v1/chat/completions",
        model = "gpt-5-mini",
        api_type = "openai",
        max_tokens = 8000,
        fetch_key = function()
          return vim.env.CHAT_ANYWHERE_KEY
        end,

        temperature = 0.3,
        top_p = 0.7,
        prompt = "You are a professional translation assistant.",

        spinner = {
          text = { "󰧞󰧞", "󰧞󰧞", "󰧞󰧞", "󰧞󰧞" },
          hl = "Title",
        },

        prefix = {
          user = { text = " ", hl = "Title" },
          assistant = { text = " ", hl = "Added" },
        },

        popwin_opts = {
          relative = "cursor",
          enter = true,
          focusable = true,
          zindex = 50,
          position = {
            row = -7,
            col = 15,
          },
          size = {
            height = 15,
            width = "50%",
          },
          border = {
            style = "single",
            text = {
              top = " Translate ",
              top_align = "center",
            },
          },
          win_options = {
            winblend = 0,
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
        },

        keys = {
          ["Input:Submit"] = { mode = "n", key = "<cr>" },
          ["Input:Cancel"] = { mode = { "n", "i" }, key = "<C-c>" },
          ["Input:Resend"] = { mode = { "n", "i" }, key = "<C-r>" },
          ["Input:HistoryNext"] = { mode = { "n", "i" }, key = "<C-j>" },
          ["Input:HistoryPrev"] = { mode = { "n", "i" }, key = "<C-k>" },
          ["Session:Close"] = { mode = "n", key = { "<esc>", "Q" } },
          ["PageUp"] = { mode = { "i", "n" }, key = "<C-b>" },
          ["PageDown"] = { mode = { "i", "n" }, key = "<C-f>" },
          ["HalfPageUp"] = { mode = { "i", "n" }, key = "<C-u>" },
          ["HalfPageDown"] = { mode = { "i", "n" }, key = "<C-d>" },
          ["JumpToTop"] = { mode = "n", key = "gg" },
          ["JumpToBottom"] = { mode = "n", key = "G" },
        },

        app_handler = {
          Translate = {
            handler = tools.qa_handler,
            opts = {
              fetch_key = function()
                return vim.env.CHAT_ANYWHERE_KEY
              end,
              url = "https://api.chatanywhere.tech/v1/chat/completions",
              model = "gpt-5-mini",
              api_type = "openai",
              component_width = "60%",
              component_height = "50%",
              query = {
                title = " 󰊿 Trans ",
                hl = { link = "Define" },
              },
              input_box_opts = {
                size = "15%",
                win_options = {
                  winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
                },
              },
              preview_box_opts = {
                size = "85%",
                win_options = {
                  winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
                },
              },
            },
          },

          WordTranslate = {
            handler = tools.flexi_handler,
            prompt = [[
You are a translation expert. Translate all text provided by the user into Chinese.

Rules:
- Only translate.
- Do not explain.
- Do not answer questions inside the text.
- Return only the translated result.
]],
            opts = {
              fetch_key = function()
                return vim.env.CHAT_ANYWHERE_KEY
              end,
              url = "https://api.chatanywhere.tech/v1/chat/completions",
              model = "gpt-5-mini",
              api_type = "openai",
              exit_on_move = false,
              enter_flexible_window = true,
              enable_cword_context = true,
            },
          },
        },
      }
    end,
    keys = {
      {
        "<leader>tt",
        "<cmd>LLMAppHandler Translate<cr>",
        mode = "n",
        desc = "Translate",
      },
      {
        "<leader>ts",
        "<cmd>LLMAppHandler WordTranslate<cr>",
        mode = "x",
        desc = "Translate Selection",
      },
    },
  },
}
