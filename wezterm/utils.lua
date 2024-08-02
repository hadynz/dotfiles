local wezterm = require 'wezterm'

local M = {};

function M.mapCmdToCtrl(key, keyOverride)
  return {
    key = key,
    mods = 'CMD',
    action = wezterm.action.SendKey { key = keyOverride, mods = 'CTRL' },
  }
end

function M.is_vim(pane)
  local process_info = pane:get_foreground_process_info()
  local process_name = process_info and process_info.name

  return process_name == "nvim" or process_name == "vim"
end

function M.find_vim_pane(tab)
  for _, pane in ipairs(tab:panes()) do
    if M.is_vim(pane) then
      return pane
    end
  end
end

function M.is_list(t)
  if type(t) ~= "table" then
    return false
  end
  -- a list has list indices, an object does not
  return ipairs(t)(t, 0) and true or false
end

--- Flatten the given list of (item or (list of (item or ...)) to a list of item.
-- (nested lists are supported)
function M.flatten_list(list)
  local flattened_list = {}
  for _, item in ipairs(list) do
    if M.is_list(item) then
      for _, sub_item in ipairs(M.flatten_list(item)) do
        table.insert(flattened_list, sub_item)
      end
    else
      table.insert(flattened_list, item)
    end
  end
  return flattened_list
end

return M;
