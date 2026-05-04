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
    "afonsofrancof/worktrees.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      require("worktrees").setup(opts)

      local worktree_utils = require("utils.worktree")
      vim.api.nvim_create_user_command("WorktreeDeleteAll", worktree_utils.delete_all, { desc = "Delete all worktrees except current" })
      vim.keymap.set("n", "<leader>gwD", "<cmd>WorktreeDeleteAll<cr>", { desc = "Delete All Worktrees" })
    end,
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
        create = "<leader>gwn",
        delete = "<leader>gwd",
        switch = "<leader>gws",
      },
    },
  },
}
