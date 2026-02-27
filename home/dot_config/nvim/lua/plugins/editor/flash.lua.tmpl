return {
  {
    "rainzm/flash-zh.nvim",
    -- 在 vscode 中加载
    cond = true,
    dependencies = { "folke/flash.nvim" },
    event = "VeryLazy",
    keys = {
      {
        "f",
        mode = { "n", "x", "o" },
        function()
          local Flash = require("flash")

          -- Action 分发器
          local function action_router(match, state)
            -- A. 如果是双字符模式（有 label2）
            if match.label2 then
              state:hide()

              -- 发起第二步跳转：只在当前分组内搜索
              Flash.jump({
                search = { max_length = 0 },
                highlight = { matches = false },
                -- 第二步只显示剩下的那个字符
                label = {
                  format = function(opts)
                    return { { opts.match.label, "FlashLabel" } }
                  end,
                },
                matcher = function(win)
                  -- 过滤：只保留第一位标签相同的项
                  return vim.tbl_filter(function(m)
                    return m.label == match.label and m.win == win
                  end, state.results)
                end,
                labeler = function(matches)
                  -- 将标签更新为第二位字符
                  for _, m in ipairs(matches) do
                    m.label = m.label2
                  end
                end,
              })

            -- B. 如果是单字符模式（无 label2）
            else
              -- 直接使用 Vim API 跳转，不调用 state:jump (因为它会递归调用 action_router)
              state:hide()
              vim.api.nvim_set_current_win(match.win)
              vim.api.nvim_win_set_cursor(match.win, match.pos)
            end
          end

          require("flash-zh").jump({
            chinese_only = false,
            action = action_router,
            jump = { autojump = true },
            -- 允许先输入一个字符
            search = {},

            label = {
              -- 禁大写
              uppercase = false,
              exclude = "",
              style = "overlay",
              -- 智能格式化
              format = function(opts)
                if opts.match.label2 then
                  -- 双字模式：两个字符都显示为 FlashLabel (红色)
                  return {
                    { opts.match.label, "FlashLabel" },
                    { opts.match.label2, "FlashLabel" },
                  }
                else
                  -- 单字模式
                  return { { opts.match.label, "FlashLabel" } }
                end
              end,
            },

            -- 标签分配
            labeler = function(matches)
              local labels = vim.split("fgrtvbdecjhuynmki;", "")

              -- A. 匹配少 -> 单字符
              if #matches <= #labels then
                for m, match in ipairs(matches) do
                  match.label = labels[m]
                  match.label2 = nil -- 标记为单字
                end

              -- B. 匹配多 -> 双字符
              else
                for m, match in ipairs(matches) do
                  local idx1 = math.floor((m - 1) / #labels) + 1
                  local idx2 = (m - 1) % #labels + 1
                  if idx1 > #labels then
                    idx1 = #labels
                  end

                  -- 逻辑标签设为第一位
                  match.label = labels[idx1]
                  -- 存储第二位供 Action 使用
                  match.label2 = labels[idx2]
                end
              end
            end,
          })
        end,
        desc = "Flash Smart Jump",
      },
    },
  },

  {
    "folke/flash.nvim",
    keys = {
      { "s", mode = { "n", "x", "o" }, false },
      { "S", mode = { "n", "x", "o" }, false },
    },
    opts = {
      labels = "fgrtvbdecjhuynmki;",
      label = { uppercase = false },
      modes = { char = { enabled = false } },
    },
  },
}
