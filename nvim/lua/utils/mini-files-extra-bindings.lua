local MiniFiles = require("mini.files")

M = {}

-- Auto command to add `g.` binding to toggle dot files
local show_dotfiles = true

function M.filter_show()
  return true
end

function M.filter_hide(fs_entry)
  return not vim.startswith(fs_entry.name, ".")
end

local toggle_dotfiles = function()
  show_dotfiles = not show_dotfiles
  local new_filter = show_dotfiles and M.filter_show or M.filter_hide
  MiniFiles.refresh({ content = { filter = new_filter } })
end

-- Add custom mappings to select file and split screen
-- @see: https://github.com/echasnovski/mini.nvim/blob/aac602e097b99a06bc84e43356f080eb6256dd21/doc/mini-files.txt#L420
local map_split = function(buf_id, lhs, direction)
  local rhs = function()
    -- Make new window and set it as target
    local new_target_window
    vim.api.nvim_win_call(MiniFiles.get_target_window(), function()
      vim.cmd(direction .. " split")
      new_target_window = vim.api.nvim_get_current_win()
    end)

    MiniFiles.set_target_window(new_target_window)
    MiniFiles.go_in({})
    MiniFiles.close()
  end

  -- Adding `desc` will result into `show_help` entries
  local desc = "Split " .. direction
  vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
end

-- Autocommand to add custom bindings on every mini.files buffer
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferCreate",
  callback = function(args)
    local buf_id = args.data.buf_id

    -- Tweak left-hand side of mapping to your liking
    vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id })
    vim.keymap.set("n", "q", MiniFiles.close, { buffer = buf_id })

    map_split(buf_id, "-", "belowright horizontal")
    map_split(buf_id, "\\", "belowright vertical")
  end,
})

return M;
