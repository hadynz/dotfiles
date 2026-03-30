local wezterm = require("wezterm")
local weztermSmartSplitsConfig = require("wezterm-smart-splits")

local config = {
	color_scheme = "Catppuccin Frappe",
	freetype_load_flags = "NO_HINTING",
	font_size = 12.40,
	font = wezterm.font_with_fallback({
		-- { family = "Atlassian Mono" },
		{ family = "JetBrains Mono", weight = "Medium" },
		{ family = "Zed Mono", weight = "Medium", scale = 1.08 },
		{ family = "Symbols Nerd Font Mono", scale = 0.75 },
	}),
	line_height = 1.10,
	use_cap_height_to_scale_fallback_fonts = true,
  tab_max_width = 50,

	macos_window_background_blur = 40,
	window_background_opacity = 1,
	-- enable_tab_bar = false,        -- Hide tab bar
	leader = {
		key = "F7",
		mods = "NONE",
		timeout_milliseconds = 1500,
	},
	colors = {
		compose_cursor = "orange", -- Cursor color when leader key is pressed
	},
	use_fancy_tab_bar = false,

	-- Dims inactive panes. Useful to make it clear which pane is active
	inactive_pane_hsb = {
		saturation = 0.70,
		brightness = 0.50,
	},

	window_decorations = "RESIZE", -- Hide window chrome
	window_padding = {
		left = 10,
		right = 8,
		top = 5,
		bottom = "0.0cell",
	},

	-- Avoid font adjustments when window manager tiling kicks in
	adjust_window_size_when_changing_font_size = false,

	-- Enable kitty keyboard protocol so apps can distinguish modified keys (e.g. Shift+Enter)
	enable_kitty_keyboard = true,

	-- Disable default key bindings
	-- disable_default_key_bindings = true,

	keys = {
		-- Forward CMD to CTRL (for VIM usage)
		{
			key = "[",
			mods = "CMD",
			action = wezterm.action.SendKey({ key = "[", mods = "CTRL" }),
		},
		{
			key = "]",
			mods = "CMD",
			action = wezterm.action.SendKey({ key = "]", mods = "CTRL" }),
		},
		{
			key = "p",
			mods = "CMD",
			action = wezterm.action.SendKey({ key = "p", mods = "CTRL" }),
		},

		-- Splitting
		{
			key = "-",
			mods = "CTRL",
			action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "\\",
			mods = "CTRL",
			action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},

		-- Palette
		{
			key = "p",
			mods = "LEADER",
			action = wezterm.action.ActivateCommandPalette,
		},

		-- Toggle terminal panes
		{
			key = "`",
			mods = "CTRL",
			action = wezterm.action_callback(function(_, pane)
				local tab = pane:tab()
				local panes = tab:panes_with_info()

				-- If there is only one pane, split it
				if #panes == 1 then
					pane:split({
						direction = "Right",
						size = 0.4,
					})
				-- If the first pane is not zoomed, zoom it (i.e. hide other panes)
				elseif not panes[1].is_zoomed then
					panes[1].pane:activate()
					tab:set_zoomed(true)
				-- If the first pane is zoomed (i.e. hiding other panes), unzoom it
				elseif panes[1].is_zoomed then
					tab:set_zoomed(false)
					panes[2].pane:activate()
				end
			end),
		},

		-- Toggle pane zoom
		{
			key = "z",
			mods = "ALT",
			action = wezterm.action.TogglePaneZoomState,
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

		-- Select All
		{
			key = "a",
			mods = "SUPER",
			action = wezterm.action_callback(function(window, pane)
				local selected = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)
				window:copy_to_clipboard(selected, "Clipboard")
			end),
		},

		-- Copy Mode (use Leader instead of CTRL to avoid hijacking Escape / Ctrl+[)
		{
			key = "[",
			mods = "LEADER",
			action = wezterm.action.ActivateCopyMode,
		},

		-- Scrolling
		{
			key = "u",
			mods = "ALT",
			action = wezterm.action.ScrollByPage(-1),
		},
		{
			key = "d",
			mods = "ALT",
			action = wezterm.action.ScrollByPage(1),
		},

		-- Clear Terminal
		{
			key = "k",
			mods = "CMD",
			action = wezterm.action.ClearScrollback("ScrollbackAndViewport"),
		},

		-- Pane selection/movement
		{
			key = ",",
			mods = "CTRL",
			action = wezterm.action.PaneSelect({
				alphabet = "1234567890",
			}),
		},
		{
			key = "m",
			mods = "CTRL",
			action = wezterm.action.PaneSelect({
				alphabet = "1234567890",
				mode = "SwapWithActive",
			}),
		},

		-- Kill current tab/panel
		{
			key = "q",
			mods = "CTRL",
			action = wezterm.action.CloseCurrentPane({ confirm = true }),
		},

	},

	mouse_bindings = {
		-- Ctrl-click will open the link under the mouse cursor
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "CMD",
			action = wezterm.action.OpenLinkAtMouseCursor,
		},
	},
}

-- Bind CMD-<#> to Navigate tabs by index
for i = 1, 8 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "CMD",
		action = wezterm.action.ActivateTab(i - 1),
	})
end

weztermSmartSplitsConfig.apply_to_config(config)

return config
