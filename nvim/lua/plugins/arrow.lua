local save_file_to_arrow = function()
  local notify = require("notify")
  local persist = require("arrow.persist")
  local utils = require("arrow.utils")

  local fileName = utils.get_current_buffer_path()
  if fileName then
    persist.save(fileName)
    notify('Added "' .. fileName .. '"', vim.log.levels.INFO, {
      title = "Arrow",
    })
  end
end

return {
  {
    "otavioschwanck/arrow.nvim",
    event = "VeryLazy",
    opts = {
      show_icons = true,
      always_show_path = true,
      separate_by_branch = true, -- Separate bookmarks for different git branches
      buffer_leader_key = "m",
      hide_handbook = true,
      window = {
        width = 130,
        col = 40
      },
      per_buffer_config = {
        lines = 6,
      },
      leader_key = ";",
      separate_save_and_remove = true, -- Disable toggle when saving buffer to arrow
    },
    keys = {
      -- {
      --   "<leader>`",
      --   function()
      --     require("arrow.ui").openMenu()
      --   end,
      --   desc = "Arrow Quick Menu",
      -- },
      -- {
      --   "<leader>h",
      --   function()
      --     save_file_to_arrow()
      --   end,
      --   desc = "Arrow File",
      -- },
      -- { "<leader>1", function() require("arrow.persist").go_to(1) end, desc = "Arrow file 1" },
      -- { "<leader>2", function() require("arrow.persist").go_to(2) end, desc = "Arrow file 2" },
      -- { "<leader>3", function() require("arrow.persist").go_to(3) end, desc = "Arrow file 3" },
      -- { "<leader>4", function() require("arrow.persist").go_to(4) end, desc = "Arrow file 4" },
      -- { "<leader>5", function() require("arrow.persist").go_to(5) end, desc = "Arrow file 5" },
      -- { "<leader>6", function() require("arrow.persist").go_to(6) end, desc = "Arrow file 6" },
      -- { "<leader>7", function() require("arrow.persist").go_to(7) end, desc = "Arrow file 7" },
      -- { "<leader>8", function() require("arrow.persist").go_to(8) end, desc = "Arrow file 8" },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      table.insert(opts.sections.lualine_c, require("arrow.statusline").text_for_statusline_with_icons())
    end,
  },
}
