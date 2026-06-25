-- WezTerm — Catppuccin Mocha to match Omarchy.
-- Docs: https://wezterm.org/config/files.html
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Theme
config.color_scheme = "Catppuccin Mocha"

-- Font (installed via brew: font-jetbrains-mono-nerd-font)
config.font = wezterm.font_with_fallback({
	"JetBrainsMono NF", -- family name as macOS registers it (not "...Nerd Font")
	"Hack Nerd Font",
})
config.font_size = 14.0
config.line_height = 1.05

-- Window
config.window_background_opacity = 0.95
config.macos_window_background_blur = 30
config.window_decorations = "RESIZE" -- borderless-ish; AeroSpace handles framing
config.window_padding = { left = 12, right = 12, top = 12, bottom = 8 }
config.adjust_window_size_when_changing_font_size = false
config.window_close_confirmation = "NeverPrompt"

-- Tabs: keep it minimal; AeroSpace/workspaces do the heavy lifting
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

-- Scrollback & misc
config.scrollback_lines = 10000
config.audible_bell = "Disabled"
config.default_cursor_style = "BlinkingBlock"

return config
