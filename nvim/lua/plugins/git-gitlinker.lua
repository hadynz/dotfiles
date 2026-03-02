return {
  "linrongbin16/gitlinker.nvim",
  cmd = "GitLink",
  opts = {},
  keys = {
    { "<Leader>gr", "<cmd>GitLink! default_branch<CR>", desc = "Open Remote File (main)" },
    { "<Leader>gR", "<cmd>GitLink!<CR>", desc = "Open Remote File" },
    { "<Leader>gB", "<cmd>GitLink! blame<CR>", desc = "Open Remote File with Blame" },
  },
}
