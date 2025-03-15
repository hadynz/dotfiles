if vim.g.vscode then
  -- VSCode extension
  require("config.keymaps-vscode")
else
  -- ordinary Neovim
  require("config.keymaps-nvim")
end

