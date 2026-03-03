-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Emit OSC 7 to notify terminal emulator (e.g. wezterm) of cwd changes
-- Why? When using git worktrees, and then create a new terminal split, we want the latter
-- to be created with cwd of the current worktree
vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    local cwd = vim.fn.getcwd()
    local hostname = vim.fn.hostname()
    io.stdout:write(string.format("\027]7;file://%s%s\027\\", hostname, cwd))
  end,
  desc = "Emit OSC 7 on directory change for terminal cwd tracking",
})

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
