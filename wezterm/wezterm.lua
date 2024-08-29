local wezterm = require 'wezterm'
local multiplexConfig = require 'wezterm-multiplex'
local smartSplitsConfig = require 'wezterm-smart-splits'
local utils = require 'utils'

local hyperKey = 'SHIFT | ALT | CTRL | SUPER'

local config = {
  -- debug_key_events = true,
  -- term = "wezterm",
  color_scheme = "Catppuccin Frappe",

  freetype_load_flags = 'NO_HINTING',
  font_size = 12.40,
  font = wezterm.font_with_fallback({
    { family = "JetBrains Mono",         weight = "Medium" },
    { family = "Symbols Nerd Font Mono", scale = 0.75 }
  }),
  line_height = 1.10,
  use_cap_height_to_scale_fallback_fonts = true,
  -- macos_window_background_blur = 40,
  -- window_background_opacity = 0.82,
  -- enable_tab_bar = false,        -- Hide tab bar
  window_decorations = 'RESIZE', -- Hide window chrome
  leader = { key = "A", mods = hyperKey, timeout_milliseconds = 1001 },
  use_fancy_tab_bar = false,
  inactive_pane_hsb = { brightness = 0.60 },
  -- font_end = "WebGpu",

  keys = {
    -- Map Mac's Cmd + key to Ctrl + key
    utils.mapCmdToCtrl('p', 'p'),
    utils.mapCmdToCtrl('[', 'o'),
    utils.mapCmdToCtrl(']', 'i'),

    -- Map Hyper + A to Ctrl + A (used as TMUX prefix)
    {
      key = 'Q',
      mods = hyperKey,
      action = wezterm.action.SendKey { key = 'q', mods = 'CTRL' },
    },
    {
      key = 'CapsLock',
      mods = 'CTRL',
      action = wezterm.action.SendKey { key = 'Escape', mods = 'CTRL' },
    },
    {
      key = '-',
      mods = 'CTRL',
      action = wezterm.action.SendKey { key = '-', mods = 'CTRL' },
    },
  },
  mouse_bindings = {
    -- Ctrl-click will open the link under the mouse cursor
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = wezterm.action.OpenLinkAtMouseCursor,
    },
  },
}

multiplexConfig.apply_to_config(config)
smartSplitsConfig.apply_to_config(config)

return config;
