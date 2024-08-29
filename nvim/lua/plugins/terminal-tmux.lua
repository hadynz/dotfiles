return {
  {
    "aserowy/tmux.nvim",
    enabled = false,
    config = function()
      require("tmux").setup({
        -- overwrite default configuration
        navigation = {
          -- enables default keybindings (C-hjkl) for normal mode
          enable_default_keybindings = true,
        },
        resize = {
          -- enables default keybindings (A-hjkl) for normal mode
          enable_default_keybindings = true,
        },
      })
    end,
  },
}
