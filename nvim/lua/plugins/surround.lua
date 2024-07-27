return {
  "echasnovski/mini.surround",

  -- Setup bindings similar to `tpope/vim-surround`
  -- @see https://github.com/echasnovski/mini.nvim/blob/2d0f10540efdbb1f5c480ebe19ce4de451936a5d/doc/mini-surround.txt#L501
  opts = {
    mappings = {
      add = "ys", -- Add surrounding in Normal and Visual modes
      delete = "ds", -- Delete surrounding
      find = "", -- Find surrounding (to the right)
      find_left = "", -- Find surrounding (to the left)
      highlight = "", -- Highlight surrounding
      replace = "cs", -- Replace surrounding
      update_n_lines = "", -- Update `n_lines`
    },
    search_method = "cover_or_next",
  },
}
