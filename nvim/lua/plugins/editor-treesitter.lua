return {
  {
    "nvim-treesitter/nvim-treesitter",
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)

      -- Parse .flow files using the python parser
      vim.filetype.add({
        extension = {
          flow = "python",
        },
      })
    end,
  }
}
