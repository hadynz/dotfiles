return {
  "aznhe21/actions-preview.nvim",
  event = "VeryLazy",
  opts = {
    telescope = vim.tbl_extend("force", require("telescope.themes").get_cursor(), {
      previewer = false,
      layout_config = {
        width = 130,
        height = 20,
      },
    }),
  },
  keys = {
    {
      "ga",
      function()
        require("actions-preview").code_actions()
      end,
      mode = { "n", "v" },
      desc = "Show Code Actions",
    },
  },
}
