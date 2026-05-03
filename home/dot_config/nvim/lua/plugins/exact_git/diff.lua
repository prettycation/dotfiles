return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    keys = {
      { "gd", "<cmd>CodeDiff<cr>", desc = "CodeDiff: Diff Explorer" },
      { "gf", "<cmd>CodeDiff file HEAD<cr>", desc = "CodeDiff: Diff File HEAD" },
      { "gh", "<cmd>CodeDiff history<cr>", desc = "CodeDiff: Diff File History" },
    },
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
