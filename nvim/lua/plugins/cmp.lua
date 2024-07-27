return {
  {
    "hrsh7th/nvim-cmp",

    -- Override LazyVim's default configuration
    config = function(_, opts)
      local cmp = require("cmp")

      -- Disable autcomplete as it can be too noisey
      opts.completion = {
        autocomplete = false,
      }

      -- Add borders -or more clarity
      opts.window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      }

      -- Mimic VSCode; both tab and enter will confirm the selection
      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<Tab>"] = cmp.mapping(cmp.mapping.confirm({ select = true }), { "i", "s" }),
        ["<CR>"] = cmp.mapping(cmp.mapping.confirm({ select = true }), { "i", "s" }),
      });

      cmp.setup(opts)
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    enabled = false
  }
}
