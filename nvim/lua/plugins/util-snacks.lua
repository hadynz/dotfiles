local filetypes = {
  { text = "markdown" },
  { text = "javascript" },
  { text = "javascriptreact" },
  { text = "lua" },
  { text = "python" },
  { text = "typescript" },
  { text = "typescriptreact" },
}

return {
  "folke/snacks.nvim",
  enabled = true,
  opts = {
    picker = {
      layout = {
        preset = "telescope",
      },
    },
    input = {
      win = {
        border = vim.g.borderStyle,
        keys = { q = "close", ["<Esc>"] = "close" },
      },
    },
  },
  keys = {
    -- Disable defaults
    { "<leader><space>", false },
    { "<leader>.", false },
    { "<leader>S", false },

    -- Picker
    { "<F5>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    { "<C-p>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    { "<leader>.", function() Snacks.picker.grep_word() end, desc = "Grep word under cursor" },
    { "<leader>gt", function() Snacks.picker.git_status() end, desc = "List modified git files" },
    { "<leader><leader>g", function() Snacks.picker.git_status() end, desc = "List modified git files" },
    { "<leader><leader>b", function() Snacks.picker.buffers() end, desc = "Open buffers" },
    { "<leader><leader>r", function() Snacks.picker.recent() end, desc = "Recent files" },

    -- Scratch
    { "-", function() require("utils.snacks.scratch").new_scratch(filetypes) end, desc = "Toggle Scratch Buffer" },
    { "_", function() require("utils.snacks.scratch").select_scratch() end, desc = "Select Scratch Buffer" },
  },
}
