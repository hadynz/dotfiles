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

        -- Up/Down to move between options
        -- @see https://github.com/mikesmithgh/nvim/blob/main/lua/plugins/cmp-cmdline.lua#L71
        ['<Down>'] = {
          c = function()
            local fn = function()
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Down>', true, false, true), 'n', true)
            end
            if cmp.visible() then
              fn = cmp.mapping.select_next_item(select_opts)
            end
            fn()
          end,
        },
        ['<Up>'] = {
          c = function()
            local fn = function()
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Up>', true, false, true), 'n', true)
            end
            if cmp.visible() then
              fn = cmp.mapping.select_prev_item(select_opts)
            end
            fn()
          end,
        },
      });

      cmp.setup(opts)
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    enabled = false
  }
}
