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
    "nvim-neotest/neotest",
    enabled = false,
    dependencies = {
      "nvim-neotest/neotest-jest"
    },
    opts = {
      adapters = {
        ["neotest-jest"] = {
          jestCommand = "yarn test --",
          jestConfigFile = function(file)
            if string.find(file, "/packages/") then
              local bla = string.match(file, "(.-/[^/]+/)src") .. "jest.config.ts"
              print("1. jestConfigFile: " .. bla)
              return bla
            end

            local path = vim.fn.getcwd() .. "/jest.config.ts"
            print("2a. jestConfigFile: " .. path)
            print("2b. file: " .. file)
            print("2c. cwd: " .. vim.fn.getcwd())
            return path
          end,
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
        }
      }
    },
    keys = {
      { "gj",         run_nearest,     desc = "Run Test", },
      { "gJ",         debug_nearest,   desc = "Debug Test", },

      { "<leader>to", open,            desc = "Show Test Output", },
      { "<leader>tn", run_nearest,     desc = "Run Test", },
      { "<leader>tn", debug_nearest,   desc = "Debug Test", },
      { "<leader>tl", run_last_test,   desc = "Run Last Test", },
      { "<leader>tL", debug_last_test, desc = "Debug Last Test", },
      { "<leader>tw", watch,           desc = "Run Watch", },
    },
  }
}
