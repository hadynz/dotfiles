return {
  {
    "hrsh7th/nvim-cmp",
    lazy = true,
    event = { "InsertEnter", "CmdlineEnter" },
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
        ['<Down>'] = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }), { 'i' }),
        ['<Up>'] = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }), { 'i' }),
      })

      cmp.setup(opts)
    end,
  },

  -- Disable Copilot auto-complete. Fallback on inline suggestions triggered manually using <C-Space>
  {
    "zbirenbaum/copilot-cmp",
    enabled = false,
  },
}
