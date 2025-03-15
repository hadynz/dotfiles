return {
  {
    'rmagatti/auto-session',
    enabled = false,
    dependencies = {
      'nvim-telescope/telescope.nvim', -- Only needed if you want to use session lens
    },
    config = function()
      require('auto-session').setup({
        auto_session_suppress_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
      })
    end,
  },
}
