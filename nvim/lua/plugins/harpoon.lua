local notify = require("notify")

return {
  "ThePrimeagen/harpoon",
  keys = {
    -- Disable default binding to Harppon file
    { "<leader>H", false },

    -- Disable default binding for Harpoon quick menu
    { "<leader>h", false },

    -- Add my preferred bindings
    {
      "<leader>`",
      function()
        local harpoon = require("harpoon")
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = "Harpoon Quick Menu",
    },
    {
      "<leader>h",
      function()
        require("harpoon"):list():add()

        local fileName = vim.fn.expand("%:t")
        notify('Added "' .. fileName .. '"', vim.log.levels.INFO, {
          title = "Harpoon",
        })
      end,
      desc = "Harpoon File",
    },
  },
}
