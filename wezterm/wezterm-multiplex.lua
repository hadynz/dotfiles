local wezterm = require 'wezterm'
local utils = require 'utils'

local M = {}

function M.apply_to_config(config)
  table.insert(config.keys, {
    -- Splitting
    {
      key    = "-",
      mods   = "LEADER",
      action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }
    },
    {
      key    = "\\",
      mods   = "LEADER",
      action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }
    },

    -- Zoom/Zen
    {
      mods = 'LEADER',
      key = 'x',
      action = wezterm.action.TogglePaneZoomState
    },

    -- Swap panes
    {
      mods = 'LEADER',
      key = 's',
      action = wezterm.action.PaneSelect {
        mode = 'SwapWithActive',
      },
    },

    -- Palette
    {
      key = "p",
      mods = "LEADER",
      action = wezterm.action.ActivateCommandPalette,
    },

    -- Navigation
    {
      key = "h",
      mods = "LEADER",
      action = wezterm.action.ActivatePaneDirection("Left"),
    },
    {
      key = "l",
      mods = "LEADER",
      action = wezterm.action.ActivatePaneDirection("Right"),
    },
    {
      key = "k",
      mods = "LEADER",
      action = wezterm.action.ActivatePaneDirection("Up"),
    },
    {
      key = "j",
      mods = "LEADER",
      action = wezterm.action.ActivatePaneDirection("Down"),
    },

    -- Toggle terminal panes
    {
      key = "`",
      mods = "CTRL",
      action = wezterm.action_callback(function(_, pane)
        local tab = pane:tab()
        local panes = tab:panes_with_info()
        if #panes == 1 then
          pane:split({
            direction = "Bottom",
            size = 0.3,
          })
        elseif not panes[1].is_zoomed then
          panes[1].pane:activate()
          tab:set_zoomed(true)
        elseif panes[1].is_zoomed then
          tab:set_zoomed(false)
          panes[2].pane:activate()
        end
      end),
    },

    -- Tab rename
    {
      key = "r",
      mods = "CMD",
      action = wezterm.action.PromptInputLine({
        description = "Enter new name for tab",
        action = wezterm.action_callback(function(window, _, line)
          if line then
            window:active_tab():set_title(line)
          end
        end),
      }),
    },

    -- Copy Mode
    {
      key = "[",
      mods = "LEADER",
      action = wezterm.action.ActivateCopyMode,
    },

    -- Clear Terminal
    {
      key = 'k',
      mods = 'CMD',
      -- action = wezterm.action.ClearScrollback('ScrollbackAndViewport'),
      action = wezterm.action.ActivatePaneDirection("Right"),
    },
  })

  config.keys = utils.flatten_list(config.keys)
end

return M
