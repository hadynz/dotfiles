local wezterm = require("wezterm")
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")

local M = {}

function M.apply_to_config(config)
	smart_splits.apply_to_config(config, {
		direction_keys = {
			move = { "h", "j", "k", "l" },
			resize = { "LeftArrow", "DownArrow", "UpArrow", "RightArrow" },
		},
		modifiers = {
			move = "CTRL",
			resize = "CTRL",
		},
	})
end

return M
