-- Ensure the config directory is in the runtime path when using symlinks
local config_path = vim.fn.stdpath("config")
if not vim.tbl_contains(vim.opt.runtimepath:get(), config_path) then
  vim.opt.runtimepath:prepend(config_path)
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
