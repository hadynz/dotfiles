-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
M = {}

local telescope_builtin_utils = require("telescope.builtin")

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

-- Redo
map("n", "U", "<C-r>", { desc = "Redo" })

-- Navigate back and forth
map("n", "<C-[>", "<C-o>", { desc = "Navigate back" })
map("n", "<C-]>", "<C-i>", { desc = "Navigate forward" })

-- Using change without yank
map({ "n", "v" }, "c", '"_c', { desc = "Change without yank" })
map({ "n", "v" }, "C", '"_C', { desc = "Change without yank" })

-- Using char delete without yank
map({ "n", "v" }, "x", '"_x', { desc = "Char delete without yank" })

-- Using delete without yank
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yank" })

-- Disable default `s` keybind - reusing it for `hop`
map("n", "s", "<nop>", { desc = "Disable default `s` keybind" })

-- Clear highlight of search, messages, floating windows
map({ "n", "i" }, "<Esc>", function()
  vim.cmd([[nohl]])                                 -- clear highlight of search
  vim.cmd([[stopinsert]])                           -- clear messages (the line below statusline)
  for _, win in ipairs(vim.api.nvim_list_wins()) do -- clear all floating windows
    if vim.api.nvim_win_get_config(win).relative == "win" then
      vim.api.nvim_win_close(win, false)
    end
  end
end, { desc = "Clear highlight search, messages, floating windows" })

-- Keep cursor centered when navigating
map("n", "k", "kzz", { desc = "Keep cursor centered on up" })
map("n", "j", "jzz", { desc = "Keep cursor centered on down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Keep cursor centered on page up" })
map("n", "<C-d>", "<C-d>zz", { desc = "Keep cursor centered on page down" })

-- Mapping for dd that doesn't yank a single empty line into the default register:
map("n", "dd", function()
  if vim.v.count == 0 and vim.api.nvim_get_current_line():match("^%s*$") then
    return '"_dd'
  else
    return "dd"
  end
end, { expr = true })

-- Console Log snippet
vim.api.nvim_set_keymap("i", "cll", "console.log();<ESC>F(a", { noremap = false, silent = true })
vim.api.nvim_set_keymap("n", "cll", "yiw%ocll'<Esc>pla, <Esc>p2b", { noremap = false, silent = true })

-- Yank History Picker
map("n", "<Leader>p", require("telescope").extensions.yank_history.yank_history, { desc = "Yank History Picker" })
map("i", "<C-r>", require("telescope").extensions.yank_history.yank_history, { desc = "Yank History Picker" })

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
map("n", "ga", vim.lsp.buf.code_action, { desc = "Code action" })
-- map("n", "gr", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "gR", telescope_builtin_utils.lsp_references, { desc = "Find all references" })
map("n", "gh", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Goto definition" })
map("n", "go", LazyVim.lsp.action["source.organizeImports"], { desc = "Format" })
map("n", "==", vim.lsp.buf.format, { desc = "Format" })

-- Diagnostics
map("n", "<M-j>", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })
map("n", "<A-k>", vim.diagnostic.goto_prev, { desc = "Prev Diagnostic" })

-- Git
map("n", "<Leader>gr", "<cmd>GitLink! default_branch<CR>", { desc = "Open Remote File (main)" })
map("n", "<Leader>gR", "<cmd>GitLink!<CR>", { desc = "Open Remote File" })
map("n", "<Leader>gB", "<cmd>GitLink! blame<CR>", { desc = "Open Remote File with Blame" })

-- Before/After
map("n", "[o", "m`O<esc>d0x``", { desc = "Empty line above" })        -- new line before
map("n", "]o", "m`o<esc>d0x``", { desc = "Empty line below" })        -- new line after
map("n", "<Leader>O", "m`O<esc>d0x``", { desc = "Empty line above" }) -- new line before
map("n", "<Leader>o", "m`o<esc>d0x``", { desc = "Empty line below" }) -- new line after
map("n", "[p", "m`P``", { desc = "Paste before" })                    -- paste before

-- No yank on visual paste
map("v", "p", "P", { noremap = true, silent = true })

-- Telescope
map("n", "<C-p>", telescope_builtin_utils.git_files, { desc = "Find File" })                                    -- iTerm maps Cmd+p to Ctrl+p
map("n", "<Leader>a", telescope_builtin_utils.commands, { desc = "Find Action" })
map("n", "<Leader>r", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", { desc = "Recent Files" }) -- iTerm maps Cmd+p to Ctrl+p

-- Testing
map("n", "<Leader>tr", "<cmd>:TestNearest<cr>", { desc = "Run test" })

-- TMUX navigation
map("n", "<C-h>", "<cmd>lua require'smart-splits'.move_cursor_left()<cr>", { desc = "Go to left window" })
map("n", "<C-j>", "<cmd>lua require'smart-splits'.move_cursor_down()<cr>", { desc = "Go to lower window" })
map("n", "<C-k>", "<cmd>lua require'smart-splits'.move_cursor_up()<cr>", { desc = "Go to upper window" })
map("n", "<C-l>", "<cmd>lua require'smart-splits'.move_cursor_right()<cr>", { desc = "Go to right window" })
map("n", "<C-Up>", "<cmd>lua require'smart-splits'.resize_up()<cr>", { desc = "Resize top" })
map("n", "<C-Down>", "<cmd>lua require'smart-splits'.resize_down()<cr>", { desc = "Resize bottom" })
map("n", "<C-Left>", "<cmd>lua require'smart-splits'.resize_left()<cr>", { desc = "Resize left" })
map("n", "<C-Right>", "<cmd>lua require'smart-splits'.resize_right()<cr>", { desc = "Resize right" })

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

function M.setup_copilot_keymaps()
  return {
    { "<leader>ap", ":Copilot panel<CR>", desc = "Copilot panel" },
  }
end

return M
