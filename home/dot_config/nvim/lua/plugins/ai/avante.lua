return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false,
    build = "powershell -NoProfile -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false",

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-mini/mini.icons",
      "MeanderingProgrammer/render-markdown.nvim",
      "saghen/blink.cmp",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = { insert_mode = true },
            use_absolute_path = true,
          },
        },
      },
    },

    opts = {
      provider = "gemini_sukaka",

      auto_suggestions_provider = nil,

      behaviour = {
        auto_suggestions = false,
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = true,
      },

      providers = {
        gemini_sukaka = {
          __inherited_from = "openai",
          endpoint = "https://catiecli.sukaka.top/v1",
          model = "gcli-gemini-3-pro-preview-search",
          api_key_name = "LLM_KEY",
          timeout = 30000,
          max_tokens = 8192,
        },

        glm_cli = {
          __inherited_from = "openai",
          endpoint = "http://127.0.0.1:8317/v1",
          model = "glm-4.7",
          api_key_name = "CLIPROXY_KEY",
          timeout = 30000,
          max_tokens = 8192,
        },
      },

      windows = {
        position = "right",
        width = 30,
        sidebar_header = {
          enabled = true,
          align = "center",
          rounded = true,
        },
        input = {
          prefix = "> ",
          height = 8,
        },
        edit = {
          border = "rounded",
          start_insert = true,
        },
        ask = {
          floating = false,
          start_insert = true,
          border = "rounded",
        },
      },

      system_prompt = [[
            ai_assistant_core_rules:
              workflow_name: 三阶段工作流
              stages:
                stage_1:
                  name: 阶段一：分析问题
                  declaration_format: 【分析问题】
                  purpose: 因为可能存在多个可选方案，要做出正确的决策，需要足够的依据。
                  must_do[3]: 理解我的意图，如果有歧义请问我,搜索所有相关代码,识别问题根因
                  proactive_discovery[7]: 发现重复代码,识别不合理的命名,发现多余的代码、类,发现可能过时的设计,发现过于复杂的设计、调用,发现不一致的类型定义,进一步搜索代码，看是否更大范围内有类似问题
                  post_action: 做完以上事项，就可以向我提问了。
                  absolute_prohibitions[4]: ❌ 修改任何代码,❌ 急于给出解决方案,❌ 跳过搜索和理解步骤,❌ 不分析就推荐方案
                  transition_rules[3]: 本阶段你要向我提问。,如果存在多个你无法抉择的方案，要问我，作为提问的一部分。,如果没有需要问我的，则直接进入下一阶段。
                stage_2:
                  name: 阶段二：制定方案
                  declaration_format: 【制定方案】
                  preconditions[1]: 我明确回答了关键技术决策。
                  must_do[3]: 列出变更（新增、修改、删除）的文件，简要描述每个文件的变化,消除重复逻辑：如果发现重复代码，必须通过复用或抽象来消除,确保修改后的代码符合DRY原则和良好的架构设计
                  transition_rules[2]: 如果新发现了向我收集的关键决策，在这个阶段你还可以继续问我，直到没有不明确的问题之后，本阶段结束。,本阶段不允许自动切换到下一阶段。
                stage_3:
                  name: 阶段三：执行方案
                  declaration_format: 【执行方案】
                  must_do[2]: 严格按照选定方案实现,修改后运行类型检查
                  absolute_prohibitions[2]: ❌ 提交代码（除非用户明确要求）,启动开发服务器
                  exception_handling: 如果在这个阶段发现了拿不准的问题，请向我提问。
              general_trigger_rule: 收到用户消息时，一般从【分析问题】阶段开始，除非用户明确指定阶段的名字。
          ]],

      pcall(function()
        local wk = require("which-key")
        wk.add({
          { "<leader>a", group = "ai" },
        })
      end),

      mappings = {
        ask = "<leader>aa",
        edit = "<leader>ae",
        refresh = "<leader>ar",
      },
    },
  },
}
