---@module "lazy"
---@type LazySpec
return {
  "neovim/nvim-lspconfig",
  {
    "pmizio/typescript-tools.nvim",
    enabled = false,
    ft = {
      "typescript",
      "javascript",
      "typescriptreact",
      "javascriptreact",
    },
    opts = {
      on_attach = function(client, bufnr)
        require("twoslash-queries").attach(client, bufnr)
      end,

      settings = {
        expose_as_code_action = "all",

        tsserver_file_preferences = {
          -- includeInlayParameterNameHints = "all",
          -- includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          -- includeInlayFunctionParameterTypeHints = true,
          -- includeInlayVariableTypeHints = true,
          -- includeInlayPropertyDeclarationTypeHints = true,
          -- includeInlayFunctionLikeReturnTypeHints = true,
          -- includeInlayEnumMemberValueHints = true,
        },
      },
    },
  },
}
