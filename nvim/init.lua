-- Fix Lua module path for symlinked/stowed configs.
-- Resolves based on the actual location of this init.lua file, which works in all
-- deployment scenarios (stow, manual symlink, nvim -u, running from dotfiles repo).
local this_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
package.path = this_dir .. "/lua/?.lua;" .. this_dir .. "/lua/?/init.lua;" .. package.path
vim.opt.runtimepath:prepend(this_dir)

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
