return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        -- hide inline errors/warnings in editor
        virtual_text = false,
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
          },
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

              -- Disable noisey inlay hints
              inlayHints = {
                enumMemberValues = { enabled = false },
                functionLikeReturnTypes = { enabled = false },
                parameterNames = { enabled = false },
                parameterTypes = { enabled = false },
                propertyDeclarationTypes = { enabled = false },
                variableTypes = { enabled = false },
              },
            },
          },

          keys = {
            -- disable plugins.extra.lang.typescript default `gR` key
            { "gR", false },
          },
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

      -- Override defaults to replace with custom keymapping
      keys[#keys + 1] = { "gr", false, mode = "n" } -- Rename; replace to use inc-rename
      keys[#keys + 1] = { "K", false, mode = "n" }  -- Hover; replace to use hover.nvim
      keys[#keys + 1] = { "gK", false, mode = "n" } -- Hover (signature help); replace to use hover.nvim
    end,
  },
}
