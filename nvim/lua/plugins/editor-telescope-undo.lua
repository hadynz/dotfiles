return {
  {
    "debugloop/telescope-undo.nvim",
    enabled = false,
    dependencies = { -- note how they're inverted to above example
      {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
      },
    },
    keys = {
      { "<leader>tu", "<cmd>Telescope undo<cr>", desc = "undo history", },
    },
    opts = {
      extensions = {
        undo = {
          layout_config = {
            preview_width = 0.8
          }
        },
      },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
      require("telescope").load_extension("undo")
    end,
  },

  {
    'mbbill/undotree',
    enabled = false,
  }
}
