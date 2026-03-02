return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    keys = {
      { "<C-h>", "<cmd>lua require'smart-splits'.move_cursor_left()<cr>", mode = { "n", "v" }, desc = "Go to left window" },
      { "<C-j>", "<cmd>lua require'smart-splits'.move_cursor_down()<cr>", mode = { "n", "v" }, desc = "Go to lower window" },
      { "<C-k>", "<cmd>lua require'smart-splits'.move_cursor_up()<cr>", mode = { "n", "v" }, desc = "Go to upper window" },
      { "<C-l>", "<cmd>lua require'smart-splits'.move_cursor_right()<cr>", mode = { "n", "v" }, desc = "Go to right window" },
      { "<C-Up>", "<cmd>lua require'smart-splits'.resize_up()<cr>", desc = "Resize top" },
      { "<C-Down>", "<cmd>lua require'smart-splits'.resize_down()<cr>", desc = "Resize bottom" },
      { "<C-Left>", "<cmd>lua require'smart-splits'.resize_left()<cr>", desc = "Resize left" },
      { "<C-Right>", "<cmd>lua require'smart-splits'.resize_right()<cr>", desc = "Resize right" },
    },
  },
}
