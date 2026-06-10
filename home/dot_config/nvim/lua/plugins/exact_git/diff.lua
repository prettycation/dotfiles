return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    opts = {
      explorer = {
        hidden = true,
        width = 30,
        view_mode = "tree",
        auto_open_on_cursor = true, -- Auto-open diff for the file under cursor while moving (j/k) in the explorer
      },
      diff = {
        -- 三栏冲突视图：left / center / right
        conflict_result_position = "center",
      },
    },
  },
}
