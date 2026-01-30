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
          -- Required to inform LSP server to send `zipfile:` URI as `zip:` (Yarn PnP need)
          init_options = { hostInfo = "neovim" },

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
    opts = {
      servers = {
        -- Apply these key overrides to all LSP servers
        ['*'] = {
          keys = {
            -- disable signature help showing in insert mode; conflicts with hjkl navigation in insert mode
            { "<c-k>", false, mode = "i" },

            -- Override defaults to replace with custom keymapping
            { "K", false, mode = "n" }, -- Hover; replace to use hover.nvim
            { "gK", false, mode = "n" }, -- Hover (signature help); replace to use hover.nvim
          },
        },
      },
    },
  },
}
