local wezterm = require 'wezterm'

local smart_splits = wezterm.plugin.require('https://github.com/mrjones2014/smart-splits.nvim')

local M = {}

function M.apply_to_config(config)
  smart_splits.apply_to_config(config, {
    -- directional keys to use in order of: left, down, up, right
    direction_keys = { 'h', 'j', 'k', 'l' },

    -- modifier keys to combine with direction_keys
    modifiers = {
      move = 'CTRL', -- modifier to use for pane movement, e.g. CTRL+h to move left
      resize = 'META', -- modifier to use for pane resize, e.g. META+h to resize to the left
    },
  })

  -- smart_splits.apply_to_config(config, {
  --   direction_keys = {
  --     move = { 'h', 'j', 'k', 'l' },
  --     resize = { 'Left', 'Down', 'Up', 'Right' },
  --   },
  --   modifiers = {
  --     move = 'CTRL',   -- modifier to use for pane movement, e.g. CTRL+h to move left
  --     resize = 'CTRL', -- modifier to use for pane resize, e.g. META+h to resize to the left
  --   },
  -- })
end

return M
