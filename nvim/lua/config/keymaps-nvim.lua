-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local cursor = require("utils.cursor")
local clipboard = require("utils.clipboard")

-- Custom keymap function that checks if a lazy keys handler exists before creating a keymap
-- @see https://github.com/aserowy/tmux.nvim/issues/92#issuecomment-1873710733
local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys

  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

-- Delete global LazyVim keymaps
vim.keymap.del({ "n" }, "<leader>l")
vim.keymap.del({ "n" }, "<leader>L")

-- Duplicate line and comment first line
map("n", "ycc", "yygccp", { remap = true })

-- Window navigation
map("n", "<leader>w\\", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>w-", "<C-w>s", { desc = "Split horizontal" })

-- LazyVim distro keymaps
map("n", "<leader>Ll", "<cmd>Lazy<CR>", { desc = "lazy.nvim" })
map("n", "<leader>Lm", "<cmd>Mason<CR>", { desc = "Mason" })
map("n", "<leader>Le", "<cmd>LazyExtras<CR>", { desc = "LazyVim Extras" })
map("n", "<leader>LL", function() LazyVim.news.changelog() end, { desc = "lazy.nvim Changelog" })

-- Redo
map("n", "U", "<C-r>", { desc = "Redo" })

-- Navigate back and forth
map("n", "<C-[>", "<C-O>", { desc = "Navigate back" })
map("n", "<C-]>", "<C-I>", { desc = "Navigate forward" })

-- Switch back and forth between last 2 buffers
map("n", "ge", "<cmd>b#<CR>", { desc = "Switch back" })

-- Using change without yank
map({ "n", "v" }, "c", '"_c', { desc = "Change without yank" })
map({ "n", "v" }, "C", '"_C', { desc = "Change without yank" })

-- Using char delete without yank
map({ "n", "v" }, "x", '"_x', { desc = "Char delete without yank" })

-- Using delete without yank
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yank" })

-- Disable default `s` keybind - reusing it for `hop`
map("n", "s", "<nop>", { desc = "Disable default `s` keybind" })
-- Select more lines in visual mode - e.g. VV for 2 lines, VVV for 3 lines
map("x", "V", "j")

-- Clear highlight of search, messages, floating windows
map({ "n", "i" }, "<Esc>", function()
  vim.cmd([[nohl]]) -- clear highlight of search
  vim.cmd([[stopinsert]]) -- clear messages (the line below statusline)
  for _, win in ipairs(vim.api.nvim_list_wins()) do -- clear all floating windows
    if vim.api.nvim_win_get_config(win).relative == "win" then vim.api.nvim_win_close(win, false) end
  end
  require("snacks.notifier").hide()
end, { desc = "Clear highlight search, messages, floating windows" })

-- Keep cursor centered when navigating
map("n", "k", function() cursor.keep_centered("k") end, { desc = "Keep cursor centered on up" })
map("n", "j", function() cursor.keep_centered("j") end, { desc = "Keep cursor centered on down" })
map("n", "G", "Gzz", { desc = "Keep cursor centered on page end" })
map("n", "<C-u>", "<C-u>zz", { desc = "Keep cursor centered on page up" })
map("n", "<C-d>", "<C-d>zz", { desc = "Keep cursor centered on page down" })
map("n", "*", "*zz", { desc = "Keep cursor centered on search next" })
map("n", "#", "#zz", { desc = "Keep cursor centered on search previous" })

-- Mapping for dd that doesn't yank a single empty line into the default register:
map("n", "dd", function()
  if vim.v.count == 0 and vim.api.nvim_get_current_line():match("^%s*$") then
    return '"_dd'
  else
    return "dd"
  end
end, { expr = true })

-- LSP keymaps
map("n", "gR", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "[R]e[n]ame" })
map("n", "gA", LazyVim.lsp.action.source, { desc = "Source Action" })
map("n", "gh", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map({ "n", "v" }, "==", function()
  LazyVim.lsp.action["source.organizeImports"]()
  LazyVim.format({ force = true })
end, { desc = "Organize imports & Format" })

-- Before/After
map("n", "[o", "m`O<esc>d0x``", { desc = "Empty line above" }) -- new line before
map("n", "]o", "m`o<esc>d0x``", { desc = "Empty line below" }) -- new line after
map("n", "<Leader>O", "m`O<esc>d0x``", { desc = "Empty line above" }) -- new line before
map("n", "<Leader>o", "m`o<esc>d0x``", { desc = "Empty line below" }) -- new line after
map("n", "[p", "m`P``", { desc = "Paste before" }) -- paste before

-- No yank on visual paste
map("v", "p", "P", { noremap = true, silent = true })

-- Mouse selection copies to clipboard
map("v", "<LeftRelease>", '"*ygv', { desc = "Mouse selection copies to clipboard" })

-- Copy file path to clipboard
map({ "n", "v" }, "<Leader>yp", function() clipboard.copy_file_path(vim.fn.expand("%")) end, { desc = "Copy relative file path" })
map({ "n", "v" }, "<Leader>yP", function() clipboard.copy_file_path(vim.fn.expand("%:p")) end, { desc = "Copy absolute file path" })
map({ "n", "v" }, "<Leader>yl", function() clipboard.copy_file_path_smart(vim.fn.expand("%")) end, { desc = "Copy relative file path with line numbers" })
