return {
  -- Install plugins (with no config)
  { "lbrayner/vim-rzip" }, -- Required for Yarn PnP
  { "sitiom/nvim-numbertoggle" }, -- Relative numbers on only for current buffer in Normal mode
  { "chrisgrieser/nvim-early-retirement", config = true, event = "VeryLazy" }, -- Auto-close inactive buffers
  { "navarasu/onedark.nvim" },

  -- Remap DAP (debug) keybindings from <leader>d to <leader>D
  {
    "mfussenegger/nvim-dap",
    -- stylua: ignore
    keys = {
      { "<leader>d", false },
      { "<leader>dB", false },
      { "<leader>db", false },
      { "<leader>dc", false },
      { "<leader>da", false },
      { "<leader>dC", false },
      { "<leader>dg", false },
      { "<leader>di", false },
      { "<leader>dj", false },
      { "<leader>dk", false },
      { "<leader>dl", false },
      { "<leader>do", false },
      { "<leader>dO", false },
      { "<leader>dP", false },
      { "<leader>dr", false },
      { "<leader>ds", false },
      { "<leader>dt", false },
      { "<leader>dw", false },
      { "<leader>DB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition" },
      { "<leader>Db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>Dc", function() require("dap").continue() end, desc = "Run/Continue" },
      { "<leader>Da", function() require("dap").continue({ before = require("lazyvim.util").get_args }) end, desc = "Run with Args" },
      { "<leader>DC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
      { "<leader>Dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
      { "<leader>Di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>Dj", function() require("dap").down() end, desc = "Down" },
      { "<leader>Dk", function() require("dap").up() end, desc = "Up" },
      { "<leader>Dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>Do", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>DO", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>DP", function() require("dap").pause() end, desc = "Pause" },
      { "<leader>Dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>Ds", function() require("dap").session() end, desc = "Session" },
      { "<leader>Dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>Dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    -- stylua: ignore
    keys = {
      { "<leader>du", false },
      { "<leader>de", false },
      { "<leader>Du", function() require("dapui").toggle({}) end, desc = "Dap UI" },
      { "<leader>De", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "x" } },
    },
  },

  -- Disable Plugins
  { "nvim-neo-tree/neo-tree.nvim", enabled = false }, -- Replaced with mini.files
  { "akinsho/bufferline.nvim", enabled = false }, -- Disable buffer tabs
  { "lukas-reineke/indent-blankline.nvim", enabled = false },
  { "folke/flash.nvim", enabled = false }, -- Disable flash; go all in on hop
  { "SmiteshP/nvim-navic", enabled = false }, -- Disable LSP code context in statusline
  { "folke/persistence.nvim", enabled = false }, -- Using auto-session instead
}
