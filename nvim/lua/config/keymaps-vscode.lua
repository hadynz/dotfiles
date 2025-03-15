local M = {}

local augroup = vim.api.nvim_create_augroup
local keymap = vim.api.nvim_set_keymap

M.my_vscode = augroup("myvscode", {})

local vscode = require("vscode")

-- Use VSCode notification
-- @see https://github.com/vscode-neovim/vscode-neovim?tab=readme-ov-file#vscodenotifymsg
vim.notify = vscode.notify

local function notify(action, opts)
  return string.format("<cmd>call VSCodeNotify('%s')<cr>", action)
end

local function v_notify(cmd)
  return string.format("<cmd>call VSCodeNotifyVisual('%s', 1)<cr>", cmd)
end

-- File operations
keymap("n", "<leader>w", notify("workbench.action.files.save"), { silent = true })
keymap("n", "<leader>q", notify("workbench.action.closeActiveEditor"), { silent = true })

-- Navigation
keymap("n", "<leader>ff", notify("workbench.action.quickOpen"), { silent = true })
keymap("n", "<leader>fd", notify("workbench.action.openRecent"), { silent = true })
keymap("n", "<leader>fc", notify("workbench.action.showCommands"), { silent = true })
keymap("v", "<leader>fc", v_notify("workbench.action.showCommands"), { silent = true })
keymap("n", "<leader>ft", notify("periscope.search"), { silent = true })

-- Editor group navigation
keymap("n", "<c-h>", notify("workbench.action.focusLeftGroup"), { silent = true })
keymap("n", "<c-j>", notify("workbench.action.focusBelowGroup"), { silent = true })
keymap("n", "<c-k>", notify("workbench.action.focusAboveGroup"), { silent = true })
keymap("n", "<c-l>", notify("workbench.action.focusRightGroup"), { silent = true })
keymap("n", "<leader>fe", notify("workbench.action.focusFirstEditorGroup"), { silent = true })

-- Tab navigation (by index)
keymap("n", "<leader>1", notify("workbench.action.openEditorAtIndex1"), { silent = true })
keymap("n", "<leader>2", notify("workbench.action.openEditorAtIndex2"), { silent = true })
keymap("n", "<leader>3", notify("workbench.action.openEditorAtIndex3"), { silent = true })
keymap("n", "<leader>4", notify("workbench.action.openEditorAtIndex4"), { silent = true })
keymap("n", "<leader>5", notify("workbench.action.openEditorAtIndex5"), { silent = true })
keymap("n", "<leader>6", notify("workbench.action.openEditorAtIndex6"), { silent = true })
keymap("n", "<leader>7", notify("workbench.action.openEditorAtIndex7"), { silent = true })
keymap("n", "<leader>8", notify("workbench.action.openEditorAtIndex8"), { silent = true })
keymap("n", "<leader>9", notify("workbench.action.openEditorAtIndex9"), { silent = true })

-- UI toggles
keymap("n", "<leader>e", notify("workbench.action.toggleSidebarVisibility"), { silent = true })
keymap("n", "<leader>ex", notify("workbench.view.explorer"), { silent = true })
keymap("n", "<leader>th", notify("workbench.action.toggleActivityBarVisibility"), { silent = true })
keymap("n", "<leader>tp", notify("workbench.action.togglePanel"), { silent = true })
keymap("n", "<leader>tt", notify("workbench.action.terminal.toggleTerminal"), { silent = true })
keymap("n", "<leader>zz", notify("workbench.action.toggleZenMode"), { silent = true })

-- Code actions
keymap("n", "<leader>gd", notify("editor.action.revealDefinition"), { silent = true })
keymap("n", "<leader>rn", notify("editor.action.rename"), { silent = true })
keymap("n", "<leader>/", notify("editor.action.commentLine"), { silent = true })
keymap("v", "<leader>/", notify("editor.action.commentLine"), { silent = true })
keymap("v", "<leader>fm", v_notify("editor.action.formatSelection"), { silent = true })
keymap("v", "<leader>ca", v_notify("editor.action.refactor"), { silent = true })
vim.keymap.set({ "n", "x" }, "<leader>r", function()
  vscode.with_insert(function()
    vscode.action("editor.action.refactor")
  end)
end)

-- Git
keymap("n", "<leader>gc", notify("git.viewChanges"), { silent = true })

-- Diagnostics/Problems
keymap("n", "<leader>xx", notify("workbench.action.problems.focus"), { silent = true })

-- Specialized features
keymap("n", "<leader>aa", notify("workbench.panel.chat"), { silent = true })
keymap("n", "<leader>md", notify("markdown.showPreview"), { silent = true })

-- Selecting
vim.keymap.set({ "n", "v" }, "<leader>ss", function()
  vscode.action("editor.action.smartSelect.expand")
end)
-- select all <leader>sa
keymap("n", "<leader>sa", notify("editor.action.selectAll"), { silent = true })

return M
