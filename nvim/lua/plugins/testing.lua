local function neotest() return require('neotest') end
local function open() neotest().output.open({ enter = true, short = false }) end
local function run_nearest() neotest().run.run() end
local function debug_nearest() neotest().run.run({ strategy = "dap" }) end
local function run_last_test() neotest().run.run_last() end
local function debug_last_test() neotest().run.run_last({ strategy = "dap" }) end
local function watch() neotest().run.run({ jestCommand = "jest --watch" }) end

return {
  {
    'vim-test/vim-test',
    enabled = false,
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>t", group = "testing" },
      },
    },
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-jest"
    },
    opts = {
      discovery = {
        enabled = false, -- Better performance?
      },
      adapters = {
        ["neotest-jest"] = {
          jestCommand = function(path)
            -- Match test file patterns to their corresponding yarn commands
            local matchers = {
              { pattern = "%.world%.test%.ts$", cmd = "yarn jest -c jest-config/jest.world.ts" },
              { pattern = "%.test%.tsx?$", cmd = "yarn jest -c jest-config/jest.config.ts" },
              { pattern = "%.looper%.localdev%.integration%.ts$", cmd = "yarn test:it:local-dev:looper" },
              { pattern = "%.localdev%.integration%.ts$", cmd = "yarn test:it:local-dev" },
              { pattern = "%.integration%.tsx?$", cmd = "yarn test:it:services" },
            }

            for _, m in ipairs(matchers) do
              if path:match(m.pattern) then
                return m.cmd
              end
            end

            -- Fallback
            return "yarn jest"
          end,
          -- Let jest resolve its own config since jestCommand handles it
          jestConfigFile = function() return nil end,
          isTestFile = function(file_path)
            if not file_path then return false end
            return file_path:match("%.world%.test%.ts$") ~= nil
              or file_path:match("%.test%.tsx?$") ~= nil
              or file_path:match("%.spec%.tsx?$") ~= nil
              or file_path:match("%.looper%.localdev%.integration%.ts$") ~= nil
              or file_path:match("%.localdev%.integration%.ts$") ~= nil
              or file_path:match("%.integration%.tsx?$") ~= nil
              or file_path:match("__tests__") ~= nil
          end,
          cwd = function(path)
            local git_root = require("lspconfig").util.root_pattern(".git")(path)
            return git_root or vim.fn.getcwd()
          end,
        }
      },
      quickfix = {
        enabled = false,
        open = false,
      },
      output_panel = {
        enabled = true,
        open = 'rightbelow vsplit | resize 30',
      },
      status = {
        enabled = true,
        virtual_text = false,
        signs = true,
      },
    },
    keys = {
      { "gj",         run_nearest,     desc = "Run Test", },
      { "gJ",         debug_nearest,   desc = "Debug Test", },

      { "<leader>to", open,            desc = "Show Test Output", },
      { "<leader>tr", run_nearest,     desc = "Run Test", },
      { "<leader>tn", debug_nearest,   desc = "Debug Test", },
      { "<leader>tl", run_last_test,   desc = "Run Last Test", },
      { "<leader>tL", debug_last_test, desc = "Debug Last Test", },
      { "<leader>tw", watch,           desc = "Run Watch", },
      { "<leader>td", "<cmd>:%s/\\<it\\.only\\>/it/g<cr>``", desc = "Delete `it.only` in file" },
      { "<leader>ti", function() require("utils.testing").toggle_it_only() end, desc = "Toggle `it.only` on line" },
    },
  }
}
