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

-- Editor
keymap("n", "j", "gj", { silent = true }) -- Enables movement over code folds
keymap("n", "k", "gk", { silent = true }) -- Enables movement over code folds
keymap("n", "u", notify("undo"), { silent = true })
keymap("n", "U", notify("redo"), { silent = true })
keymap("n", "==", notify("editor.action.formatDocument"), { silent = true })

-- Duplicate line and comment first line
vim.keymap.set("n", "ycc", function()
  vim.cmd("normal! yy")
  vscode.call("editor.action.commentLine")
  vim.cmd("normal! p")
end, { noremap = true, silent = true })

-- New lines
keymap("n", "]o", notify("editor.action.insertLineAfter"), { silent = true })
keymap("n", "[o", notify("editor.action.insertLineBefore"), { silent = true })
keymap("n", "<leader>o", notify("editor.action.insertLineAfter"), { silent = true })
keymap("n", "<leader>O", notify("editor.action.insertLineBefore"), { silent = true })

-- Testing
keymap("n", "<leader>tr", notify("extension.runJest"), { silent = true })
keymap("n", "<leader>td", notify("extension.debugJest"), { silent = true })
keymap("n", "<leader>tn", notify("extension.debugJest"), { silent = true })

-- Navigation
keymap("n", "<F5>", notify("workbench.action.quickOpen"), { silent = true })
keymap("n", "<leader>ff", notify("workbench.action.quickOpen"), { silent = true })
keymap("n", "<leader><leader>r", notify("workbench.action.openRecent"), { silent = true })
keymap("n", "<leader>fr", notify("workbench.action.openRecent"), { silent = true })
keymap("n", "<leader>fc", notify("workbench.action.showCommands"), { silent = true })
keymap("v", "<leader>fc", v_notify("workbench.action.showCommands"), { silent = true })
keymap("n", "<leader>/", notify("television.ToggleFileFinder"), { silent = true })
vim.keymap.set("n", "<leader>.", function()
  vscode.action("television.ToggleTextFinder", {
    args = {
      query = vim.fn.expand("<cword>"),
    },
  })
end)

-- Harpoon
keymap("n", "<leader>`", notify("vscode-harpoon.editEditors"), { silent = true })
keymap("n", "<leader>h", notify("vscode-harpoon.addEditor"), { silent = true })
keymap("n", "<leader>1", notify("vscode-harpoon.gotoEditor1"), { silent = true })
keymap("n", "<leader>2", notify("vscode-harpoon.gotoEditor2"), { silent = true })
keymap("n", "<leader>3", notify("vscode-harpoon.gotoEditor3"), { silent = true })
keymap("n", "<leader>4", notify("vscode-harpoon.gotoEditor4"), { silent = true })
keymap("n", "<leader>5", notify("vscode-harpoon.gotoEditor5"), { silent = true })
keymap("n", "<leader>6", notify("vscode-harpoon.gotoEditor6"), { silent = true })
keymap("n", "<leader>7", notify("vscode-harpoon.gotoEditor7"), { silent = true })
keymap("n", "<leader>8", notify("vscode-harpoon.gotoEditor8"), { silent = true })
keymap("n", "<leader>9", notify("vscode-harpoon.gotoEditor9"), { silent = true })

-- Bookmarks
keymap("n", "m`", notify("bookmarks.list"), { silent = true })
keymap("n", "md", notify("bookmarks.clear"), { silent = true })
keymap("n", "mm", notify("bookmarks.toggle"), { silent = true })

-- UI toggles
keymap("n", "<leader>e", notify("voil.openPanelCurrentDir"), { silent = true })
keymap("n", "<leader>E", notify("workbench.files.action.focusFilesExplorer"), { silent = true })
keymap("n", "<leader>th", notify("workbench.action.toggleActivityBarVisibility"), { silent = true })
keymap("n", "<leader>tp", notify("workbench.action.togglePanel"), { silent = true })
keymap("n", "<leader>tt", notify("workbench.action.terminal.toggleTerminal"), { silent = true })
keymap("n", "<leader>zz", notify("workbench.action.toggleZenMode"), { silent = true })

-- Splits
keymap("n", "<leader>w-", notify("workbench.action.splitEditorOrthogonal"), { silent = true })
keymap("n", "<leader>w\\", notify("workbench.action.splitEditor"), { silent = true })
keymap("n", "<leader>wq", notify("workbench.action.closeEditorsAndGroup"), { silent = true })
keymap("n", "<leader>wo", notify("workbench.action.closeEditorsInOtherGroups"), { silent = true })

-- Code actions
keymap("n", "ga", notify("editor.action.quickFix"), { silent = true })
keymap("n", "gi", notify("editor.action.goToImplementation"), { silent = true })
keymap("n", "gr", notify("editor.action.goToReferences"), { silent = true })
keymap("n", "gR", notify("references-view.findReferences"), { silent = true })
keymap("n", "go", notify("editor.action.organizeImports"), { silent = true })
keymap("n", "<leader>rn", notify("editor.action.rename"), { silent = true })
keymap("n", "<leader>ra", notify("editor.action.refactor"), { silent = true })
keymap("n", "<leader>cn", notify("editor.action.rename"), { silent = true })

-- fold support
keymap("n", "zM", notify("editor.foldAll"), { silent = true })
keymap("n", "zR", notify("editor.unfoldAll"), { silent = true })
keymap("n", "zc", notify("editor.fold"), { silent = true })
keymap("n", "zC", notify("editor.foldRecursively"), { silent = true })
keymap("n", "zo", notify("editor.unfold"), { silent = true })
keymap("n", "zO", notify("editor.unfoldRecursively"), { silent = true })
keymap("n", "za", notify("editor.toggleFold"), { silent = true })

-- Git
keymap("n", "<leader>gg", notify("lazygit-vscode.toggle"), { silent = true })
keymap("n", "<leader>go", notify("git.openFile"), { silent = true }) -- Go from file diff to actual file
keymap("n", "<leader>gr", notify("gitlens.openFileRevisionFrom"), { silent = true }) -- Open Git file revision
keymap("n", "<leader>gb", notify("gitlens.openFileOnRemoteFrom"), { silent = true }) -- Open Remote file in browser
keymap("n", "<leader>gdf", notify("git.openChange"), { silent = true }) -- Diff for current file
keymap("n", "<leader>gdd", notify("git.viewChanges"), { silent = true }) -- Diff for all changed files

-- AI
keymap("n", "<leader>aa", notify("aichat.focuschatpaneaction"), { silent = true })
keymap("i", "<leader>aa", notify("aichat.focuschatpaneaction"), { silent = true })
keymap("n", "<leader>an", notify("composer.createNew"), { silent = true })
keymap("i", "<leader>an", notify("composer.createNew"), { silent = true })

-- Specialized features
keymap("n", "<leader>md", notify("markdown.showPreview"), { silent = true })
keymap("n", "<leader>uz", notify("workbench.action.toggleZenMode"), { silent = true })

-- Yank
keymap("n", "<leader>yp", notify("copyRelativeFilePath"), { silent = true }) -- Copy relative file path of active file

-- Diagnostics
keymap("n", "]d", notify("editor.action.marker.next"), { silent = true })
keymap("n", "[d", notify("editor.action.marker.next"), { silent = true })

return M
