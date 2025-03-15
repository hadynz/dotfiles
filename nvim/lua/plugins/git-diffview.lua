return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<Leader>gh", "<cmd>DiffviewFileHistory<CR>", desc = "Diff File" },
    { "<Leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff View" },
  },
}
