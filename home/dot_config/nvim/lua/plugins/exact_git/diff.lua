return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    opts = {
      explorer = {
        width = 30,
        view_mode = "tree",
      },
      diff = {
        -- 三栏冲突视图：left / center / right
        conflict_result_position = "center",
      },
    },
  },
}
