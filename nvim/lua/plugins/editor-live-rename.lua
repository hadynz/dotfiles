return {
  "saecki/live-rename.nvim",
  keys = {
    { "gR", function() require("live-rename").rename() end, desc = "Rename" },
  }
}
