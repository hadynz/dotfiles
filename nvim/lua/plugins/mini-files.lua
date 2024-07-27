local MiniFiles = require("mini.files")

-- Toggle visibility of mini.files explorer
local toggle_minifiles = function(...)
  if not MiniFiles.close() then
    MiniFiles.open(...)
  end
end

-- Predicate function to hide dot files
return {
  "echasnovski/mini.files",
  version = "*",
  config = function()
    local f = require("utils.mini-files-extra-bindings")
    require("utils.mini-files-git-integration")

    require("mini.files").setup({
      content = {
        filter = f.filter_hide,
      },
      mappings = {
        close = "<Esc>",
        go_in_plus = "<CR>",
      },
      options = {
        use_as_default_explorer = true,
      },
      windows = {
        preview = true,
        width_focus = 60,
        width_preview = 120,
      },
    })
  end,
  keys = {
    {
      "<leader>E",
      function()
        local lazyvimRoot = require("lazyvim.util.root")
        toggle_minifiles(lazyvimRoot.git(), true)
      end,
      desc = "Open mini.files (Git dir)",
    },
    {
      "<leader>e",
      function()
        toggle_minifiles(vim.api.nvim_buf_get_name(0), true)
      end,
      desc = "Open mini.files (Cwd)",
    },
  },
}
