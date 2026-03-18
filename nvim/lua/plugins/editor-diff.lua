return {
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    keys = {
      { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "Code Diff (local)" },
      { "<leader>gD", "<cmd>CodeDiff main...<cr>", desc = "Code Diff (against main)" },
      { "<leader>gh", "<cmd>CodeDiff history %<cr>", desc = "Code Diff File History" },
      { "<leader>gH", "<cmd>CodeDiff history<cr>", desc = "Code Diff Repo History" },
    },
  },
}
