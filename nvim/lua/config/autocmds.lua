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

-- Toggle relative numbers for active panes only
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "FocusGained" }, {
  callback = function()
    vim.wo.relativenumber = true
  end,
})
vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave", "FocusLost" }, {
  callback = function()
    vim.wo.relativenumber = false
  end,
})
