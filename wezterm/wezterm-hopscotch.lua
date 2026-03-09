local wezterm = require("wezterm")

local M = {}

-- Hopscotch CLI paths (checked in order)
local hopscotch_paths = {
	"/Applications/Hopscotch.app/Contents/MacOS/Hopscotch",
	"/Users/hosman/Library/Developer/Xcode/DerivedData/Hopscotch-afcjwundmknxlpaoftzsjhiwkzhg/Build/Products/Debug/Hopscotch.app/Contents/MacOS/Hopscotch",
}

--- Find the hopscotch CLI binary, returns the path or nil
function M.find()
	for _, path in ipairs(hopscotch_paths) do
		local f = io.open(path, "r")
		if f then
			f:close()
			return path
		end
	end
	return nil
end

--- Invoke hopscotch spatial focus in the given direction
---@param direction string "left"|"right"|"up"|"down"
function M.spatial(direction)
	local hopscotch = M.find()
	if hopscotch then
		wezterm.background_child_process({
			hopscotch,
			"spatial",
			direction,
		})
	end
end

return M
