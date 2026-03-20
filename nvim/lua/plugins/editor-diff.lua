local diff_file_a = nil

return {
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    keys = {
      { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "Branch Diff (against HEAD)" },
      { "<leader>dd", "<cmd>CodeDiff<cr>", desc = "Branch Diff (against HEAD)" },

      { "<leader>gD", "<cmd>CodeDiff main...<cr>", desc = "Branch Diff (against main)" },
      { "<leader>dm", "<cmd>CodeDiff main...<cr>", desc = "Branch Diff (against main)" },

      { "<leader>gh", "<cmd>CodeDiff history %<cr>", desc = "File History Diff" },
      { "<leader>df", "<cmd>CodeDiff history %<cr>", desc = "File History Diff" },
      {
        "<leader>da",
        function()
          diff_file_a = vim.fn.expand("%:p")
          vim.notify("Diff file A: " .. vim.fn.fnamemodify(diff_file_a, ":~:."), vim.log.levels.INFO)
        end,
        desc = "Select Diff File A (left)",
      },
      {
        "<leader>db",
        function()
          if not diff_file_a then
            vim.notify("Select File A first with <leader>da", vim.log.levels.WARN)
            return
          end
          local file_b = vim.fn.expand("%:p")
          if file_b == diff_file_a then
            vim.notify("File B is the same as File A, pick a different file", vim.log.levels.WARN)
            return
          end
          vim.cmd("CodeDiff file " .. vim.fn.fnameescape(diff_file_a) .. " " .. vim.fn.fnameescape(file_b))
          diff_file_a = nil
        end,
        desc = "Select Diff File B (right) & compare",
      },
    },
    opts = {
      keymaps = {
        view = {
          toggle_layout = "<leader>tl", -- Remap to avoid conflict with hop's "t" binding
        },
      },
    },
  },
}
