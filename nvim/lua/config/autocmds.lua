-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Disable new line comment
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
  desc = "Disable New Line Comment",
})


-- Add bindings when entering Quickfix
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "<A-j>", "<cmd>cnext<cr>", { buffer = true, remap = false, desc = "Navigate down quickfix" })
    vim.keymap.set("n", "<A-k>", "<cmd>cprev<cr>", { buffer = true, remap = false, desc = "Navigate up quickfix" })
    vim.keymap.set("n", "<A-h>", "<cmd>cnfile<cr>", { buffer = true, remap = false, desc = "Navigate up quickfix file" })
    vim.keymap.set("n", "<A-l>", "<cmd>cNfile<cr>", { buffer = true, remap = false, desc = "Navigate down quickfix file" })
  end,
})
