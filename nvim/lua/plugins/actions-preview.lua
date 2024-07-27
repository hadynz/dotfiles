return {
  "aznhe21/actions-preview.nvim",
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
