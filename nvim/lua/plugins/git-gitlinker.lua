return {
  "linrongbin16/gitlinker.nvim",
  cmd = "GitLink",
  opts = {},
  keys = {
    { "<Leader>gr", "<cmd>GitLink! default_branch<CR>", mode = { "n", "v" }, desc = "Open Remote File (main)" },
    { "<Leader>gR", "<cmd>GitLink!<CR>", mode = { "n", "v" }, desc = "Open Remote File" },
    { "<Leader>gB", "<cmd>GitLink! blame<CR>", mode = { "n", "v" }, desc = "Open Remote File with Blame" },
    { "<Leader>yr", "<cmd>GitLink default_branch<CR>", mode = { "n", "v" }, desc = "Yank Remote URL (main)" },
    { "<Leader>yR", "<cmd>GitLink<CR>", mode = { "n", "v" }, desc = "Yank Remote URL" },
  },
}
