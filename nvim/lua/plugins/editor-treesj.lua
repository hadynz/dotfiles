return {
  -- Split/Join lines
  {
    "Wansmer/treesj",
    keys = {
      {
        "<leader>s",
        function()
          require("treesj").toggle()
        end,
        desc = "󰗈 Split-join lines",
      },
    },
    opts = {
      use_default_keymaps = false,
      cursor_behavior = "start",
      max_join_length = 200,
    },
  },
}
