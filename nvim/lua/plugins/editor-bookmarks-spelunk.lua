return {
  {
    "Wilson/spelunk.nvim",
    enabled = false,
    dependencies = {
      'nvim-lua/plenary.nvim',           -- For window drawing utilities
      'nvim-telescope/telescope.nvim',   -- Optional: for fuzzy search capabilities
      'nvim-treesitter/nvim-treesitter', -- Optional: for showing grammar context
    },
    opts = {
      enable_persist = true, -- Directory scoped bookmark persistence
      window_mappings = {
        help = '?',
        close = { 'q', '<esc>' },
        delete_bookmark = 'dd',
        bookmark_up = '<C-k>',
        bookmark_down = '<C-j>',
      },
      enable_status_col_display = true,
    }
  },
}
