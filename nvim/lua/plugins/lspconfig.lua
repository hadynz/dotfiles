return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        -- hide inline errors/warnings in editor
        virtual_text = false
      },
      servers = {
        tsserver = {
          init_options = {
            hostInfo = "neovim",
            maxTsServerMemory = 18432,
            -- tsserver = {
            --   logFile = vim.fn.stdpath("cache") .. "/tsserver.log",
            --   logVerbosity = "verbose",
            --   logLevel = "verbose",
            --   telemetry = {
            --     enable = false,
            --   },
            -- }
          }
        },
        vtsls = {
          -- Required to inform LSP server to send `zipfile:` URI as `zip:` (Yarn PNP need)
          init_options = { hostInfo = "neovim" },

          root_dir = function()
            local lazyvimRoot = require("lazyvim.util.root")
            return lazyvimRoot.git()
          end,

          settings = {
            typescript = {
              tsdk = ".yarn/sdks/typescript/lib",
            },
          },

          keys = {
            -- disable plugins.extra.lang.typescript default `gR` key
            { "gR", false },
          }
        },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()

      -- disable signature help showing in insert mode; conflicts with hjkl navigation in insert mode
      keys[#keys + 1] = { "<c-k>", false, mode = "i" }

      -- replace default variable rename with `inc-rename` lib
      keys[#keys + 1] = {
        "gr",
        function()
          local inc_rename = require("inc_rename")
          return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
        end,
        expr = true,
        desc = "Rename variable",
        has = "rename",
      }
    end
  }
}
