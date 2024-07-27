local actions = require("telescope.actions")

return {
  {
    "nvim-telescope/telescope.nvim",

    opts = {
      defaults = {
        mappings = {
          i = {
            ["<Esc>"] = actions.close,
            ["<C-E>"] = { "<Esc>", type = "command" },
          },
        },
      },
    },

    keys = {
      { "<Leader><space>", false }
    }
  },

  -- Customise look and feel of Telescope
  {
    "catppuccin/nvim",
    opts = {
      custom_highlights = function(colors)
        return {
          TelescopeResultsTitle = { bg = colors.sapphire, fg = colors.mantle },
          TelescopeResultsNormal = { bg = colors.mantle },
          TelescopeResultsBorder = { bg = colors.mantle, fg = colors.sapphire },
          TelescopeMatching = { bg = colors.sapphire, fg = colors.mantle },

          TelescopePromptTitle = { bg = colors.pink, fg = colors.mantle },
          TelescopePromptNormal = { bg = colors.mantle },
          TelescopePromptBorder = { bg = colors.mantle, fg = colors.pink },

          TelescopePreviewTitle = { bg = colors.green, fg = colors.mantle },
          TelescopePreviewNormal = { bg = colors.mantle },
          TelescopePreviewBorder = { bg = colors.mantle, fg = colors.green },
        }
      end,
    },
  },
}
