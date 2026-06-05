local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- Performance
config.front_end = "WebGpu"
config.max_fps = 120
config.animation_fps = 120
config.enable_wayland = true

-- Font
config.font = wezterm.font_with_fallback({
  { family = "JetBrainsMono Nerd Font", weight = "Medium" },
  { family = "JetBrains Mono", weight = "Medium" },
  "Fira Code",
  "monospace",
})
config.font_size = 12.5
config.line_height = 1.15

-- Catppuccin Mocha
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.92
config.text_background_opacity = 0.9

-- Window
config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.initial_cols = 140
config.initial_rows = 38

-- Tab bar
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.tab_max_width = 28

config.colors = {
  tab_bar = {
    background = "#11111b",
    active_tab = { bg_color = "#313244", fg_color = "#cdd6f4" },
    inactive_tab = { bg_color = "#181825", fg_color = "#6c7086" },
    inactive_tab_hover = { bg_color = "#1e1e2e", fg_color = "#cdd6f4" },
    new_tab = { bg_color = "#181825", fg_color = "#6c7086" },
    new_tab_hover = { bg_color = "#313244", fg_color = "#cdd6f4" },
  },
}

-- Cursor
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 600

-- Scrollback
config.scrollback_lines = 10000

-- Shell
config.default_prog = { "/bin/bash", "--login" }

-- Launch menu: multiple profiles in one click
config.launch_menu = {
  { label = " Bash", args = { "/bin/bash", "--login" } },
  { label = " Zsh", args = { "/bin/zsh", "--login" } },
  { label = " Zellij", args = { "/home/deva/.local/bin/zellij" } },
  { label = " Zellij (new session)", args = { "/home/deva/.local/bin/zellij", "-s", "work" } },
  { label = " Python REPL", args = { "/home/deva/.local/share/mise/installs/python/latest/bin/python3" } },
  { label = " Node REPL", args = { "/home/deva/.local/share/mise/installs/node/latest/bin/node" } },
  { label = " btop", args = { "btop" } },
}

-- Keybindings
config.keys = {
  -- Pane splitting
  { key = "d", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "e", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Pane navigation (vim-style)
  { key = "h", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },

  -- Pane resize
  { key = "H", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Left", 5 }) },
  { key = "L", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Right", 5 }) },
  { key = "K", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Up", 3 }) },
  { key = "J", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Down", 3 }) },

  -- Pane management
  { key = "Enter", mods = "CTRL|SHIFT", action = act.TogglePaneZoomState },
  { key = "x", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },

  -- Tab management
  { key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
  { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
  { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },

  -- Direct tab access (Alt+1..9)
  { key = "1", mods = "ALT", action = act.ActivateTab(0) },
  { key = "2", mods = "ALT", action = act.ActivateTab(1) },
  { key = "3", mods = "ALT", action = act.ActivateTab(2) },
  { key = "4", mods = "ALT", action = act.ActivateTab(3) },
  { key = "5", mods = "ALT", action = act.ActivateTab(4) },
  { key = "6", mods = "ALT", action = act.ActivateTab(5) },
  { key = "7", mods = "ALT", action = act.ActivateTab(6) },
  { key = "8", mods = "ALT", action = act.ActivateTab(7) },
  { key = "9", mods = "ALT", action = act.ActivateTab(8) },

  -- Copy/Paste
  { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

  -- Font size
  { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = act.ResetFontSize },

  -- Launch menu (profile picker)
  { key = "p", mods = "CTRL|SHIFT", action = act.ShowLauncher },

  -- Quick Zellij in new tab
  { key = "z", mods = "CTRL|SHIFT", action = act.SpawnCommandInNewTab({
    args = { "/home/deva/.local/bin/zellij" },
  }) },

  -- Command palette
  { key = "P", mods = "CTRL|SHIFT|ALT", action = act.ActivateCommandPalette },

  -- Scroll (PageUp/Down so Ctrl+Shift+d stays the split-pane key)
  { key = "PageUp", mods = "CTRL|SHIFT", action = act.ScrollByPage(-0.5) },
  { key = "PageDown", mods = "CTRL|SHIFT", action = act.ScrollByPage(0.5) },

  -- Search
  { key = "f", mods = "CTRL|SHIFT", action = act.Search("CurrentSelectionOrEmptyString") },

  -- Toggle fullscreen
  { key = "F11", mods = "NONE", action = act.ToggleFullScreen },
}

-- Mouse bindings
config.mouse_bindings = {
  { event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.OpenLinkAtMouseCursor },
}

-- Misc
config.warn_about_missing_glyphs = false
config.check_for_updates = false
config.audible_bell = "Disabled"
config.exit_behavior = "Close"

return config
