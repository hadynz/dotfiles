local M = {}

--- Delete all git worktrees except the current working directory.
--- Prompts for confirmation before deleting.
function M.delete_all()
  local result = vim.fn.systemlist("git worktree list --porcelain 2>/dev/null")
  local worktrees = {}
  local current_dir = vim.fn.getcwd()

  for _, line in ipairs(result) do
    local path = line:match("^worktree (.+)$")
    if path and path ~= current_dir then
      table.insert(worktrees, path)
    end
  end

  if #worktrees == 0 then
    vim.notify("No other worktrees to delete", vim.log.levels.INFO)
    return
  end

  vim.ui.select({ "Yes", "No" }, {
    prompt = string.format("Delete all %d worktrees (excluding current)?", #worktrees),
  }, function(choice)
    if choice ~= "Yes" then return end

    local utils = require("worktrees").utils
    local deleted = 0
    for _, path in ipairs(worktrees) do
      if utils.delete_worktree(path) then
        deleted = deleted + 1
      end
    end
    vim.notify(string.format("Deleted %d/%d worktrees", deleted, #worktrees), vim.log.levels.INFO)
  end)
end

return M
