return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Let LazyVim handle the treesitter configuration
      -- Just add custom filetype associations
      vim.filetype.add({
        extension = {
          flow = "python",
        },
      })
      return opts
    end,
  },
}
