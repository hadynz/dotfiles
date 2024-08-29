return {
  { -- scrollbar with information
    "lewis6991/satellite.nvim",
    event = "VeryLazy",
    opts = {
      winblend = 10, -- little transparency, since hard to see in many themes otherwise
      handlers = {
        cursor = { enable = false },
        marks = { enable = false }, -- prevents buggy mark mappings
        quickfix = { enable = true },
      },
    },
  },
}
