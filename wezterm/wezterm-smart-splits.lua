local wezterm = require("wezterm")
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
local hopscotch = require("wezterm-hopscotch")

local M = {}

local Directions = { "Left", "Down", "Up", "Right" }
local hopscotch_dirs = { Left = "left", Down = "down", Up = "up", Right = "right" }

--- Check if there's an adjacent pane in the given direction using geometry
local function has_pane_in_direction(tab, current_pane_id, direction)
	local panes = tab:panes_with_info()
	local current = nil
	for _, p in ipairs(panes) do
		if p.pane:pane_id() == current_pane_id then
			current = p
			break
		end
	end
	if not current then
		return false
	end

	for _, p in ipairs(panes) do
		if p.pane:pane_id() ~= current_pane_id then
			local overlaps_vertically = p.top < current.top + current.height and p.top + p.height > current.top
			local overlaps_horizontally = p.left < current.left + current.width and p.left + p.width > current.left

			if direction == "Left" and p.left < current.left and overlaps_vertically then
				return true
			elseif direction == "Right" and p.left > current.left and overlaps_vertically then
				return true
			elseif direction == "Up" and p.top < current.top and overlaps_horizontally then
				return true
			elseif direction == "Down" and p.top > current.top and overlaps_horizontally then
				return true
			end
		end
	end
	return false
end

function M.apply_to_config(config)
	if not config.keys then
		config.keys = {}
	end

	local move_keys = { "h", "j", "k", "l" }
	local resize_keys = { "LeftArrow", "DownArrow", "UpArrow", "RightArrow" }
	local move_mods = "CTRL"
	local resize_mods = "CTRL"

	-- Move: vim passthrough + pane navigation + hopscotch at edge
	for idx, key in ipairs(move_keys) do
		local direction = Directions[idx]
		table.insert(config.keys, {
			key = key,
			mods = move_mods,
			action = wezterm.action_callback(function(win, pane)
				if smart_splits.is_vim(pane) then
					win:perform_action({ SendKey = { key = key, mods = move_mods } }, pane)
				elseif has_pane_in_direction(win:active_tab(), pane:pane_id(), direction) then
					win:perform_action({ ActivatePaneDirection = direction }, pane)
				else
					hopscotch.spatial(hopscotch_dirs[direction])
				end
			end),
		})
	end

	-- Resize: delegated to smart-splits (no edge concern)
	for idx, key in ipairs(resize_keys) do
		local direction = Directions[idx]
		table.insert(config.keys, {
			key = key,
			mods = resize_mods,
			action = wezterm.action_callback(function(win, pane)
				if smart_splits.is_vim(pane) then
					win:perform_action({ SendKey = { key = key, mods = resize_mods } }, pane)
				else
					win:perform_action({ AdjustPaneSize = { direction, 3 } }, pane)
				end
			end),
		})
	end
end

return M
