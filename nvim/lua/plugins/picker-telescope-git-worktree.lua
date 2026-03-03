return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>gw", group = "worktrees" },
      },
    },
  },

  {
    "polarmutex/git-worktree.nvim",
    enabled = false,
    version = "^2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      change_directory_command = "cd",
      update_on_change = true,
      update_on_change_command = "e .",
      clearjumps_on_change = true,
      autopush = false,
    },
    keys = {
      {
        "<leader>gws",
        function() require("snacks-worktree").pick_git_worktree() end,
        desc = "Pick Git Worktree",
      },
      {
        "<leader>gwc",
        function() require("snacks-worktree").create_worktree() end,
        desc = "Create Git Worktree",
      },
    },
  },

  {
    "afonsofrancof/worktrees.nvim",
    event = "VeryLazy",
    opts = {
      -- Specify where to create worktrees relative to git common dir
      -- The common dir is the .git dir in a normal repo or the root dir of a bare repo
      base_path = "../../canvas-worktrees", -- Parent directory of common dir

      -- Template for worktree folder names
      -- This is only used if you don't specify the folder name when creating the worktree
      path_template = "{branch}", -- Default: use branch name

      -- Command names (optional)
      commands = {
        create = "WorktreeCreate",
        delete = "WorktreeDelete",
        switch = "WorktreeSwitch",
      },

      -- Key mappings for interactive UI (optional)
      mappings = {
        create = "<leader>gwc",
        delete = "<leader>gwd",
        switch = "<leader>gws",
      },
    },
  },
}
