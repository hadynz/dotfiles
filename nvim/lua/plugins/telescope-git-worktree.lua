local function switch_worktrees()
  require("telescope").extensions.git_worktree.git_worktrees()
end

local function create_worktrees()
  require("telescope").extensions.git_worktree.create_git_worktree()
end

local function on_switch_worktrees()
  local Worktree = require("git-worktree")
end

return {
  {
    "awerebea/git-worktree.nvim",
    branch = "handle_changes_in_telescope_api",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      config = function()
        require("telescope").load_extension("git_worktree")
        on_switch_worktrees()
      end,
    },
    keys = {
      { "<leader>gw", switch_worktrees, desc = "Switch git worktree" },
      { "<leader>gW", create_worktrees, desc = "Create git worktree" },
    },
  },
}
