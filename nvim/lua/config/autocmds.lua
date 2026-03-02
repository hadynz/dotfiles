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

-- Refocus floating terminal window when navigating back (e.g. LazyGit)
-- Handles both internal window navigation and external focus (e.g. wezterm/tmux pane)
local _last_win = nil

--- Find and focus a floating terminal window, if one exists
local function focus_floating_terminal()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" then
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "terminal" then
          vim.api.nvim_set_current_win(win)
          vim.cmd("startinsert")
          return
        end
      end
    end
  end
end

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    _last_win = vim.api.nvim_get_current_win()
  end,
  desc = "Track last window for floating terminal refocus",
})
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    -- Don't refocus if we just left a floating terminal (user is navigating away)
    if _last_win and vim.api.nvim_win_is_valid(_last_win) then
      local last_config = vim.api.nvim_win_get_config(_last_win)
      if last_config.relative ~= "" then
        return
      end
    end
    focus_floating_terminal()
  end,
  desc = "Refocus floating terminal on window enter",
})
vim.api.nvim_create_autocmd("FocusGained", {
  callback = function()
    focus_floating_terminal()
  end,
  desc = "Refocus floating terminal when Neovim regains focus",
})

-- Add window navigation bindings for terminal buffers (e.g. LazyGit)
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local opts = { buffer = buf, silent = true }
    vim.keymap.set("t", "<C-h>", function()
      vim.cmd("stopinsert")
      require("smart-splits").move_cursor_left()
    end, vim.tbl_extend("force", opts, { desc = "Go to left window" }))
    vim.keymap.set("t", "<C-j>", function()
      vim.cmd("stopinsert")
      require("smart-splits").move_cursor_down()
    end, vim.tbl_extend("force", opts, { desc = "Go to lower window" }))
    vim.keymap.set("t", "<C-k>", function()
      vim.cmd("stopinsert")
      require("smart-splits").move_cursor_up()
    end, vim.tbl_extend("force", opts, { desc = "Go to upper window" }))
    vim.keymap.set("t", "<C-l>", function()
      vim.cmd("stopinsert")
      require("smart-splits").move_cursor_right()
    end, vim.tbl_extend("force", opts, { desc = "Go to right window" }))
  end,
  desc = "Terminal window navigation with smart-splits",
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
