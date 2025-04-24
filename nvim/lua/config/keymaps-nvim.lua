-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
M = {}

-- local wk = require("which-key")

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

local function toggle_it_only()
  local line = vim.api.nvim_get_current_line() -- Get the current line in the buffer
  -- If the line contains 'it.only', replace with `it`
  if line:match("^%s*it%.only%s*%(") then
    line = line:gsub("it%.only", "it")
  -- If line contains `it`, replace with `it.only`
  elseif line:match("^%s*it%s*%(") then
    -- Replace 'it' with 'it.only'
    line = line:gsub("it", "it.only", 1)
  else
    return
  end
  vim.api.nvim_set_current_line(line) -- Set the modified line back to the buffer
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
-- wk.add({ "<leader>L", group = "LazyVim" })
map("n", "<leader>Ll", "<cmd>Lazy<CR>", { desc = "lazy.nvim" })
map("n", "<leader>Lm", "<cmd>Mason<CR>", { desc = "Mason" })
map("n", "<leader>Le", "<cmd>LazyExtras<CR>", { desc = "LazyVim Extras" })
map("n", "<leader>LL", function()
  LazyVim.news.changelog()
end, { desc = "lazy.nvim Changelog" })

-- Redo
map("n", "U", "<C-r>", { desc = "Redo" })

-- Navigate back and forth
map("n", "<C-[>", "<C-O>", { desc = "Navigate back" })
map("n", "<C-]>", "<C-I>", { desc = "Navigate forward" })

-- Switch back and forth between last 2 buffers
map("n", "ge", "<cmd>b#<CR>", { desc = "Switch back" })

-- Git Worktree management
map("n", "<leader>gw", function()
  require("telescope").extensions.g_worktree.list()
end, { desc = "Switch git worktree" })
map("n", "<leader>gW", function()
  require("telescope").extensions.g_worktree.create()
end, { desc = "Create git worktree" })

-- Using change without yank
map({ "n", "v" }, "c", '"_c', { desc = "Change without yank" })
map({ "n", "v" }, "C", '"_C', { desc = "Change without yank" })

-- Using char delete without yank
map({ "n", "v" }, "x", '"_x', { desc = "Char delete without yank" })

-- Using delete without yank
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yank" })

-- Disable default `s` keybind - reusing it for `hop`
map("n", "s", "<nop>", { desc = "Disable default `s` keybind" })
-- map("n", "s", "<nop>", { desc = "Disable default `s` keybind" })
-- Select more lines in visual mode - e.g. VV for 2 lines, VVV for 3 lines
map("x", "V", "j")

-- Testing
map("n", "<Leader>tr", "<cmd>:TestNearest<cr>", { desc = "Run test" })
map("n", "<leader>td", "<cmd>:%s/\\<it\\.only\\>/it/g<cr>``", { desc = "Delete `it.only` in file" })
map("n", "<leader>ti", toggle_it_only, { desc = "Toggle `it.only` on line", noremap = true, silent = true })

-- Clear highlight of search, messages, floating windows
map({ "n", "i" }, "<Esc>", function()
  vim.cmd([[nohl]]) -- clear highlight of search
  vim.cmd([[stopinsert]]) -- clear messages (the line below statusline)
  for _, win in ipairs(vim.api.nvim_list_wins()) do -- clear all floating windows
    if vim.api.nvim_win_get_config(win).relative == "win" then
      vim.api.nvim_win_close(win, false)
    end
  end
  require("snacks.notifier").hide()
end, { desc = "Clear highlight search, messages, floating windows" })

-- Invoke VIM command to move j/k directions + keep cursor centered for any buffers with line numbers
-- This method means all plugin buffers will be excluded and use standard vim behaviour
local keep_cursor_centered = function(jk_direction)
  local excluded_filetypes = { "harpoon", "minifiles" }

  -- Invoke norm command if filetype is in excluded list
  for _, filetype in ipairs(excluded_filetypes) do
    if vim.o.filetype == filetype then
      vim.cmd("norm! " .. jk_direction)
      return
    end
  end

  vim.cmd("norm! " .. jk_direction .. "zz") -- Keep cursor centered on all vertical movements
end

-- Keep cursor centered when navigating
map("n", "k", function()
  keep_cursor_centered("k")
end, { desc = "Keep cursor centered on up" })
map("n", "j", function()
  keep_cursor_centered("j")
end, { desc = "Keep cursor centered on down" })
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

-- In insert mode, either move cursor right, or trigger next copilot suggestion
local move_right = function()
  local copilot = require("copilot.suggestion")
  if copilot.is_visible() then
    copilot.next()
    return
  else
    vim.cmd("normal! l")
  end
end
-- In insert mode, either move cursor left, or trigger previous copilot suggestion
local move_left = function()
  local copilot = require("copilot.suggestion")
  if copilot.is_visible() then
    copilot.prev()
    return
  else
    vim.cmd("normal! h")
  end
end

-- HJKL insert mode navigation
map("i", "<C-h>", move_left, { desc = "Move cursor left" })
map("i", "<C-j>", "<Down>", { desc = "Move cursor down" })
map("i", "<C-k>", "<Up>", { desc = "Move cursor up" })
map("i", "<C-l>", move_right, { desc = "Move cursor right" })

-- LSP keymaps
-- map("n", "gr", telescope_builtin_utils.lsp_references, { desc = "Find all references" })
map("n", "gR", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "[R]e[n]ame" })
map("n", "gA", LazyVim.lsp.action.source, { desc = "Source Action" })
map("n", "gh", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "go", LazyVim.lsp.action["source.organizeImports"], { desc = "Format" })
map({ "n", "v" }, "==", function()
  LazyVim.format({ force = true })
end, { desc = "Format" })

-- Git
map("n", "<Leader>gr", "<cmd>GitLink! default_branch<CR>", { desc = "Open Remote File (main)" })
map("n", "<Leader>gR", "<cmd>GitLink!<CR>", { desc = "Open Remote File" })
map("n", "<Leader>gB", "<cmd>GitLink! blame<CR>", { desc = "Open Remote File with Blame" })

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

map("n", "<leader>ug", "<cmd>:lua require('tint').toggle()<cr>", { desc = "Toggle tint" })

-- Copy File Path
local copy_file_path = function(path)
  vim.fn.setreg("+", path)
  vim.notify("Copied relative file path to clipboard: " .. path)
end

local resolve_file_path = function()
  local choice_callback = function(_choice, index)
    local path = index == 1 and vim.fn.expand("%") or vim.fn.expand("%:p")
    copy_file_path(path)
  end
  vim.ui.select(
    { "Copy relative file path", "Copy absolute file path" },
    { prompt = "Copy File Path" },
    choice_callback
  )
end

map("n", "<Leader>yf", resolve_file_path, { desc = "Copy File Path" })

--- TMUX navigation
map("n", "<C-h>", "<cmd>lua require'smart-splits'.move_cursor_left()<cr>", { desc = "Go to left window" })
map("n", "<C-j>", "<cmd>lua require'smart-splits'.move_cursor_down()<cr>", { desc = "Go to lower window" })
map("n", "<C-k>", "<cmd>lua require'smart-splits'.move_cursor_up()<cr>", { desc = "Go to upper window" })
map("n", "<C-l>", "<cmd>lua require'smart-splits'.move_cursor_right()<cr>", { desc = "Go to right window" })
map("n", "<C-Up>", "<cmd>lua require'smart-splits'.resize_up()<cr>", { desc = "Resize top" })
map("n", "<C-Down>", "<cmd>lua require'smart-splits'.resize_down()<cr>", { desc = "Resize bottom" })
map("n", "<C-Left>", "<cmd>lua require'smart-splits'.resize_left()<cr>", { desc = "Resize left" })
map("n", "<C-Right>", "<cmd>lua require'smart-splits'.resize_right()<cr>", { desc = "Resize right" })

return M
