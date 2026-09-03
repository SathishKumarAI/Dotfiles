local wezterm = require("wezterm")
local act = wezterm.action

-- Session persistence across restarts/reboots. resurrect.wezterm saves the
-- workspace/window/tab/PANE layout + each pane's cwd to disk, so a full layout
-- can be brought back after quitting WezTerm or rebooting. (The unix mux domain
-- further down already keeps panes alive across a GUI close/crash; resurrect
-- adds on-disk state that ALSO survives a reboot.) The plugin is archived but
-- working; the first load fetches it from GitHub, then it's cached locally.
-- pcall so a failed fetch/plugin never stops WezTerm from starting.
local ok_resurrect, resurrect = pcall(function()
  return wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
end)
if ok_resurrect then
  -- Autosave every 5 min: on-disk state stays fresh with no keypress, so a
  -- crash/reboot loses at most ~5 min of layout changes.
  resurrect.state_manager.periodic_save({
    interval_seconds = 5 * 60,
    save_workspaces = true,
    save_windows = true,
    save_tabs = true,
  })

  -- Autosave on window close. WezTerm fires no dedicated "window-closed" GUI
  -- event, but a window always loses focus as it closes, so saving whenever a
  -- window goes unfocused captures the layout right before it disappears (and
  -- also every time you switch away). Cheap: writes the current workspace state.
  wezterm.on("window-focus-changed", function(window)
    if window and not window:is_focused() and ok_resurrect then
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
    end
  end)

  -- Production hardening: surface plugin failures to the WezTerm log instead of
  -- failing silently. Without this, a bad save/load path is invisible.
  wezterm.on("resurrect.error", function(err)
    wezterm.log_error("resurrect error: " .. tostring(err))
  end)
end

local config = wezterm.config_builder()

-- Performance
config.front_end = "WebGpu"
config.max_fps = 120
config.animation_fps = 120
-- Native Wayland. XWayland is unavailable in this session (XOpenDisplay fails),
-- so enable_wayland=false made wezterm fail to start entirely. If the old
-- Mutter explicit-sync crash ("Protocol error os error 71") returns, upgrade
-- wezterm or switch front_end below to "OpenGL".
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
-- Ligatures + contextual alternates (JetBrainsMono Nerd Font ships them):
-- == -> != => become connected glyphs. calt/clig = context-aware shaping.
config.harfbuzz_features = { "calt=1", "liga=1", "clig=1" }

-- Catppuccin Mocha
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.92
config.text_background_opacity = 0.9

-- Subtle vertical Mocha gradient behind the text for depth. Stops stay close
-- to the base/crust colors so it reads as a gentle shade, not a rainbow. The
-- window_background_opacity above still applies, so transparency is preserved.
config.window_background_gradient = {
  orientation = "Vertical",
  colors = { "#1e1e2e", "#181825", "#11111b" },
  interpolation = "Linear",
  blend = "Rgb",
}

-- Window
config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
-- Normal app window: TITLE gives GNOME's server-side titlebar with
-- minimize/maximize/close buttons + a draggable bar; RESIZE adds the resize
-- border so you can drag any edge. This is what makes WezTerm behave like a
-- regular Mutter window (Super+drag move, double-click titlebar to maximize,
-- header-bar buttons). Use "NONE" for a borderless clean edge (loses buttons),
-- or "RESIZE" for borders-only without the titlebar.
--
-- INTEGRATED_BUTTONS|RESIZE drops the separate GNOME titlebar and instead draws
-- the minimize/maximize/close buttons INSIDE the tab bar — a smaller, cleaner
-- frame with no wasted titlebar row. Requires the fancy tab bar at the top (see
-- Tab bar section). Move the window with the mouse by dragging an empty part of
-- the tab bar, or Super+left-drag anywhere.
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_close_confirmation = "NeverPrompt"
-- Fallback geometry if the mux can't maximize (e.g. headless / no GUI).
config.initial_cols = 140
config.initial_rows = 38

-- Start maximized so the window fills the screen on every launch. Maximize
-- (not ToggleFullScreen) keeps the tab bar + window controls visible; F11
-- still toggles true borderless fullscreen on demand.
wezterm.on("gui-startup", function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- Window management: snap to screen halves, maximize, restore, fullscreen.
-- WezTerm exposes window geometry via the GUI window API; we compute against the
-- active screen so left/right halves work on whatever monitor the window is on.
-- (On Wayland the GNOME compositor may override positioning — if a snap is
-- ignored, GNOME's own Super+Left / Super+Right tiling still works.)
local function active_screen()
  local screens = wezterm.gui.screens()
  return screens.active or screens.main
end

-- Snap the window to the left or right half of the active screen.
local function snap_half(window, side)
  local s = active_screen()
  if not s then return end
  local gw = window:gui_window()
  local half = math.floor(s.width / 2)
  gw:set_inner_size(half, s.height)
  if side == "left" then
    gw:set_position(s.x, s.y)
  else
    gw:set_position(s.x + half, s.y)
  end
end

wezterm.on("snap-left", function(window)
  snap_half(window, "left")
end)
wezterm.on("snap-right", function(window)
  snap_half(window, "right")
end)
-- Half-height/centered "restore" size — a comfortable non-maximized window.
wezterm.on("snap-center", function(window)
  local s = active_screen()
  if not s then return end
  local gw = window:gui_window()
  local w = math.floor(s.width * 0.6)
  local h = math.floor(s.height * 0.7)
  gw:set_inner_size(w, h)
  gw:set_position(s.x + math.floor((s.width - w) / 2), s.y + math.floor((s.height - h) / 2))
end)
wezterm.on("win-maximize", function(window)
  window:gui_window():maximize()
end)
wezterm.on("win-restore", function(window)
  window:gui_window():restore()
end)

-- Toggle the tab bar on demand. WezTerm can't reveal it on mouse-hover (no such
-- API), so this gives keyboard control: hide it for a clean full-screen view,
-- show it again when you need tabs. (hide_tab_bar_if_only_one_tab already hides
-- it automatically whenever a single tab is open.)
wezterm.on("toggle-tab-bar", function(window)
  local overrides = window:get_config_overrides() or {}
  if overrides.enable_tab_bar == false then
    overrides.enable_tab_bar = true
  else
    overrides.enable_tab_bar = false
  end
  window:set_config_overrides(overrides)
end)

-- Toggle background transparency: flip between the configured 0.92 and fully
-- solid (1.0) on the fly — handy when a screenshot/readability needs no bleed.
wezterm.on("toggle-opacity", function(window)
  local overrides = window:get_config_overrides() or {}
  if overrides.window_background_opacity == 1.0 then
    overrides.window_background_opacity = nil  -- back to config default (0.92)
  else
    overrides.window_background_opacity = 1.0
  end
  window:set_config_overrides(overrides)
end)

-- Custom tab titles: index + a Nerd Font icon for the running process + title,
-- with the active tab accented in Mauve and a [Z] marker when the pane is zoomed.
local PROC_ICONS = {
  ["nvim"] = " ",
  ["vim"] = " ",
  ["git"] = " ",
  ["lazygit"] = " ",
  ["python"] = " ",
  ["python3"] = " ",
  ["node"] = " ",
  ["docker"] = " ",
  ["ssh"] = " ",
  ["btop"] = " ",
  ["htop"] = " ",
  ["zellij"] = " ",
  ["zsh"] = " ",
  ["bash"] = " ",
  ["claude"] = "󰚩 ",
  ["herdr"] = "󰕰 ",
}

local function tab_title(tab)
  local title = tab.tab_title
  if title and #title > 0 then return title end
  return tab.active_pane.title
end

wezterm.on("format-tab-title", function(tab, _tabs, _panes, _cfg, _hover, max_width)
  local proc = (tab.active_pane.foreground_process_name or ""):gsub(".*/", "")
  local icon = PROC_ICONS[proc] or " "
  local zoom = tab.active_pane.is_zoomed and " [Z]" or ""
  local title = tab_title(tab)
  -- Claude Code is a Node wrapper, so it usually reports as "node" and the
  -- process-name lookup above misses it. Fall back to the pane title, which
  -- carries "claude", so agent tabs stay identifiable at a glance.
  if not PROC_ICONS[proc] and title:lower():find("claude", 1, true) then
    icon = PROC_ICONS["claude"]
  end
  -- Leave room for "  N  " + icon + zoom marker.
  local budget = max_width - 8
  if #title > budget and budget > 1 then
    title = title:sub(1, budget - 1) .. "…"
  end
  local label = string.format(" %d %s%s%s ", tab.tab_index + 1, icon, title, zoom)
  if tab.is_active then
    return {
      { Background = { Color = "#313244" } },
      { Foreground = { Color = "#cba6f7" } },
      { Attribute = { Intensity = "Bold" } },
      { Text = label },
    }
  end
  return {
    { Background = { Color = "#181825" } },
    { Foreground = { Color = "#6c7086" } },
    { Text = label },
  }
end)

-- ── herdr agent state in the status bar ─────────────────────────────────────
-- Shows how many agents are working/blocked without switching to their tabs.
--
-- WHY A POLLER AND NOT A DIRECT CALL: update-status fires several times per
-- second, and wezterm has no async subprocess API in the config — every
-- run_child_process blocks the event loop. So a timer refreshes a cache and
-- update-status only ever READS that cache. One subprocess every few seconds
-- instead of hundreds a minute.
--
-- `herdr agent list` emits a single line of JSON (it has no --json flag; that
-- errors). Real shape:
--   {"result":{"agents":[{"agent":"claude","agent_status":"idle",...}],...}}
-- We COUNT agent_status occurrences rather than parsing JSON: no dependency,
-- and an upstream schema change degrades to "no pill" instead of a broken config.
local HERDR_POLL_SECONDS = 3
local HERDR_MAX_FAILURES = 3
local herdr_state = { working = 0, blocked = 0, total = 0 }
local herdr_failures = 0

-- Plain (non-pattern) substring count, so JSON punctuation needs no escaping.
local function count_substr(s, needle)
  local n, pos = 0, 1
  while true do
    local i = string.find(s, needle, pos, true)
    if not i then break end
    n, pos = n + 1, i + 1
  end
  return n
end

local function herdr_poll()
  local ok, success, stdout = pcall(wezterm.run_child_process, { "herdr", "agent", "list" })
  if ok and success and stdout then
    herdr_failures = 0
    herdr_state.working = count_substr(stdout, '"agent_status":"working"')
    herdr_state.blocked = count_substr(stdout, '"agent_status":"blocked"')
    herdr_state.total = count_substr(stdout, '"agent_status":"')
  else
    herdr_failures = herdr_failures + 1
    herdr_state.working, herdr_state.blocked, herdr_state.total = 0, 0, 0
    -- Give up permanently rather than spawning a doomed process every 3s for the
    -- rest of the session when herdr isn't installed or no server is running.
    if herdr_failures >= HERDR_MAX_FAILURES then
      wezterm.log_info("herdr status polling stopped: " .. HERDR_MAX_FAILURES ..
        " consecutive failures (herdr missing or no server). Restart WezTerm to retry.")
      return
    end
  end
  wezterm.time.call_after(HERDR_POLL_SECONDS, herdr_poll)
end

-- Start after a short delay so it never competes with GUI startup.
wezterm.time.call_after(1, herdr_poll)

-- Status bar: workspace pill on the left; leader + active key-table on the right.
wezterm.on("update-status", function(window, _pane)
  -- Left: active workspace name in a Mauve pill.
  window:set_left_status(wezterm.format({
    { Background = { Color = "#cba6f7" } },
    { Foreground = { Color = "#1e1e2e" } },
    { Attribute = { Intensity = "Bold" } },
    { Text = "  " .. window:active_workspace() .. " " },
    { Background = { Color = "#1e1e2e" } },
    { Foreground = { Color = "#cba6f7" } },
    { Text = " " },
  }))

  -- Right: herdr agent state + leader indicator + modal key-table name.
  local cells = {}

  -- Agent pill, read from the cache the poller above maintains. Hidden entirely
  -- when no agents are running, so a non-agent session gains no extra chrome.
  -- Red the moment anything is blocked — that's the state needing you.
  if herdr_state.total > 0 then
    local blocked = herdr_state.blocked > 0
    table.insert(cells, { Background = { Color = blocked and "#f38ba8" or "#a6e3a1" } })
    table.insert(cells, { Foreground = { Color = "#1e1e2e" } })
    table.insert(cells, { Attribute = { Intensity = "Bold" } })
    local label = "  󰚩 " .. herdr_state.total
    if herdr_state.working > 0 then
      label = label .. "  ● " .. herdr_state.working .. " working"
    end
    if blocked then
      label = label .. "  ▲ " .. herdr_state.blocked .. " blocked"
    end
    table.insert(cells, { Text = label .. " " })
    table.insert(cells, { Background = { Color = "#1e1e2e" } })
    table.insert(cells, { Text = " " })
  end

  if window:leader_is_active() then
    table.insert(cells, { Background = { Color = "#f9e2af" } })
    table.insert(cells, { Foreground = { Color = "#1e1e2e" } })
    table.insert(cells, { Attribute = { Intensity = "Bold" } })
    table.insert(cells, { Text = "  LEADER " })
    table.insert(cells, { Background = { Color = "#1e1e2e" } })
  end
  local kt = window:active_key_table()
  if kt then
    table.insert(cells, { Background = { Color = "#fab387" } })
    table.insert(cells, { Foreground = { Color = "#1e1e2e" } })
    table.insert(cells, { Attribute = { Intensity = "Bold" } })
    table.insert(cells, { Text = "  " .. kt:upper() .. " " })
  end
  table.insert(cells, { Background = { Color = "#1e1e2e" } })
  table.insert(cells, { Text = " " })
  window:set_right_status(wezterm.format(cells))
end)

-- Tab bar
-- Fancy tab bar is required for INTEGRATED_BUTTONS (window controls live here
-- instead of a titlebar). Fancy tab bar only renders at the TOP, so the bottom
-- placement is off. Tab bar stays visible even with one tab — otherwise the
-- min/max/close buttons would vanish and you'd have no mouse way to move/close
-- the window.
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false
config.tab_max_width = 28

config.colors = {
  -- Selection, cursor, scrollbar and pane-split lines (Catppuccin Mocha).
  selection_fg = "#1e1e2e",
  selection_bg = "#f5e0dc",
  cursor_bg = "#f5e0dc",
  cursor_fg = "#1e1e2e",
  cursor_border = "#f5e0dc",
  scrollbar_thumb = "#585b70",
  split = "#585b70",
  compose_cursor = "#fab387",
  tab_bar = {
    background = "#11111b",
    active_tab = { bg_color = "#313244", fg_color = "#cdd6f4" },
    inactive_tab = { bg_color = "#181825", fg_color = "#6c7086" },
    inactive_tab_hover = { bg_color = "#1e1e2e", fg_color = "#cdd6f4" },
    new_tab = { bg_color = "#181825", fg_color = "#6c7086" },
    new_tab_hover = { bg_color = "#313244", fg_color = "#cdd6f4" },
  },
}

-- Fancy tab bar frame (holds the integrated window buttons). Catppuccin Mocha
-- crust/base so the frame reads as one piece with the tab bar colors above; a
-- slightly smaller font keeps the bar compact so it doesn't cost much height.
config.window_frame = {
  active_titlebar_bg = "#11111b",
  inactive_titlebar_bg = "#11111b",
  font = wezterm.font({ family = "JetBrainsMono Nerd Font", weight = "Bold" }),
  font_size = 11.0,
}

-- Cursor
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 600
-- Smooth the blink instead of a hard on/off flash.
config.cursor_blink_ease_in = "EaseOut"
config.cursor_blink_ease_out = "EaseIn"

-- Visual depth / clarity
-- Dim panes that aren't focused so the active one stands out.
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.7 }
-- Show a scrollbar (handy with the 10k-line scrollback).
config.enable_scroll_bar = true
-- Non-intrusive flash on the bell (audible bell stays Disabled below).
config.visual_bell = {
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 75,
  fade_in_function = "EaseIn",
  fade_out_function = "EaseOut",
  target = "CursorColor",
}

-- Scrollback. Left at 10k on purpose: herdr has its own scrollback plus history
-- replay for agent runs, so there's no reason to spend RAM twice on a machine
-- that already needs OOM/swap tooling.
config.scrollback_lines = 10000

-- Kitty keyboard protocol. Lets TUIs receive key events the legacy encoding
-- cannot express — notably SHIFT+ENTER as distinct from Enter, which is how
-- Claude Code inserts a newline in its prompt instead of submitting it.
-- If an older TUI starts mis-reading keys, this is the line to revert.
config.enable_kitty_keyboard = true

-- Shell — zsh so autosuggestions / syntax-highlighting / fzf+fd are active
-- (configured in ~/.zshrc; bash does not get them).
config.default_prog = { "/bin/zsh", "--login" }

-- Persistent local sessions. A unix mux domain keeps panes/tabs alive in a
-- background server, so they survive closing/crashing the GUI. Attach with
-- `Leader+u` (act.AttachDomain) or from a shell: `wezterm connect unix`.
-- For always-persistent launches, run `wezterm connect unix` instead of plain
-- `wezterm` (left opt-in so the normal launch path / maximize stays simple).
config.unix_domains = { { name = "unix" } }

-- Agent launchers (Claude Code, herdr). Both run as HOST processes even though
-- the WezTerm GUI is a Flatpak, and both resolve through the shell's PATH
-- (~/.local/bin symlinks, mise shims) — so every spawn goes through a LOGIN
-- shell. See docs/fixes/wezterm-flatpak-env-leak.md.
--
-- The trailing `exec zsh -l` is load-bearing: exit_behavior = "Close" would
-- otherwise destroy the tab the moment claude exits, taking the session's whole
-- scrollback with it, and a "command not found" would flash past unreadably.
local function agent_cmd(cmd)
  return { "/bin/zsh", "-lc", cmd .. "; exec /bin/zsh -l" }
end

-- Current pane's cwd, so a spawned agent starts in the repo you're looking at.
-- get_current_working_dir() returns a Url object on current WezTerm and a plain
-- string on older builds; handle both, and return nil rather than a bad path so
-- the spawn just falls back to the default.
local function pane_cwd(pane)
  local ok, cwd = pcall(function() return pane:get_current_working_dir() end)
  if not ok or not cwd then return nil end
  if type(cwd) == "string" then
    return (cwd:gsub("^file://[^/]*", ""))
  end
  return cwd.file_path
end

-- Spawn an agent in a new tab, or in a 50/50 split beside the current pane.
local function spawn_agent(cmd, split)
  return wezterm.action_callback(function(window, pane)
    local spawn = { args = agent_cmd(cmd), cwd = pane_cwd(pane) }
    if split then
      window:perform_action(act.SplitPane({
        direction = "Right", command = spawn, size = { Percent = 50 },
      }), pane)
    else
      window:perform_action(act.SpawnCommandInNewTab(spawn), pane)
    end
  end)
end

-- Launch menu: multiple profiles in one click (Zsh first = default)
config.launch_menu = {
  { label = " Zsh", args = { "/bin/zsh", "--login" } },
  { label = " Bash", args = { "/bin/bash", "--login" } },
  -- Bare names resolve via PATH so this works on any host (system pkgs,
  -- mise shims, ~/.local/bin) without hardcoding per-machine absolute paths.
  { label = " Zellij", args = { "zellij" } },
  { label = " Zellij (new session)", args = { "zellij", "-s", "work" } },
  { label = " Python REPL", args = { "python3" } },
  { label = " Node REPL", args = { "node" } },
  { label = " btop", args = { "btop" } },
  -- Agents. Login-shell wrapped for the same PATH/Flatpak reason as above.
  { label = "󰚩 Claude Code", args = agent_cmd("claude") },
  { label = "󰚩 Claude Code (resume)", args = agent_cmd("claude --resume") },
  { label = "󰕰 Herdr (agent multiplexer)", args = agent_cmd("herdr") },
}

-- Leader key (tmux-style). Ctrl+a then a second key. Existing Ctrl+Shift binds
-- are untouched; this just adds a second, modal way to drive panes/workspaces.
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

-- Quick-select copy: type the Leader+Space hint, then a letter, to copy any
-- match to the clipboard. These ADD to WezTerm's built-in patterns (URLs, etc).
config.quick_select_patterns = {
  -- file:line[:col] FIRST — agent, compiler and stack-trace output is full of
  -- these, and it must beat the generic path rule below, or "src/main.py:42"
  -- gets grabbed without the line number that made it worth copying.
  "[\\w./~+-]+\\.[A-Za-z0-9_]+:\\d+(?::\\d+)?",
  "[0-9a-f]{7,40}",                     -- git commit SHAs
  "(?:[0-9]{1,3}\\.){3}[0-9]{1,3}",     -- IPv4 addresses
  "0x[0-9a-fA-F]+",                     -- hex literals
  "[~./][\\w./@%+-]+",                  -- file paths
  "[\\w.+-]+@[\\w.-]+\\.[A-Za-z]{2,}",  -- email addresses
}

-- Cheatsheet overlay (Leader+?). WezTerm has no text-overlay API, so this writes
-- the keymap to a temp file and pages it in a new tab (q to close). Keep in sync
-- with the binds below when you add/remove keys.
local CHEATSHEET = [[
  WezTerm keybindings — Leader = Ctrl+a (then a key within 1s)

  PANES
    Ctrl+Shift+d / e        split horizontal / vertical
    Leader+| / -            split horizontal / vertical
    Ctrl+Shift+h/j/k/l      focus pane left/down/up/right
    Ctrl+Shift+Enter        zoom pane (toggle)   |  Leader+z  zoom
    Ctrl+Shift+x            close pane           |  Leader+x  close
    Leader+p                pick pane by letter
    Leader+r                resize mode (hjkl, Esc exits)
    Ctrl+Shift+Alt+H/J/K/L  resize pane

  TABS
    Ctrl+Shift+t            new tab    |  Ctrl+Shift+w / Leader+q  close
    Ctrl+Tab / Ctrl+Shift+Tab   next / prev tab
    Alt+1..9                jump to tab 1..9

  WORKSPACES (apps)
    Leader+n                new named workspace
    Leader+w                workspace switcher (fuzzy)
    Leader+Tab / Leader+]   next workspace   |  Leader+Shift+Tab  prev
    Ctrl+Shift+Space        fuzzy switcher (apps/tabs/workspaces/commands)

  SCROLLBACK & SEARCH  (needs shell integration, on by default)
    Leader+Up / Down        jump to previous / next shell prompt
    Leader+y                copy the LAST command's output
    Leader+[                copy mode (vim motions)
    Ctrl+Shift+f / Leader+f search
    Ctrl+Shift+PageUp/Down  scroll half page

  SELECT / COPY
    Leader+Space            quick-select (URLs, SHAs, IPs, paths, emails)
    Leader+o                open a URL on screen in the browser
    Leader+e                char / emoji picker (copies)
    Ctrl+Shift+c / v        copy / paste     |  drag = copy, middle-click = paste

  WINDOW
    Super+Left / Right      snap to left / right half   (Leader+h / l too)
    Super+Up / Down         maximize / restore
    Leader+m / c            maximize / center
    Super+Return / F11      fullscreen        |  Leader+Shift+F  fullscreen
    Super+h / Leader+,      minimize
    Leader+b                toggle tab bar
    Leader+Shift+O          toggle transparency

  AGENTS  (Leader+a, then one key)
    Leader+a c              Claude Code in a new tab (inherits cwd)
    Leader+a s              Claude Code in a split beside this pane
    Leader+a r / k          claude --resume / --continue
    Leader+a h              herdr (agent multiplexer; its own prefix is Ctrl+g)
    Leader+a y              copy last command + its output as a markdown block
    Leader+a Y              copy the whole scrollback

  LAUNCH
    Ctrl+Shift+p            profile launcher  |  Ctrl+Shift+z  Zellij in new tab
    Ctrl+Shift+Alt+P        command palette
    Leader+u                attach persistent mux session  (shell: wtp)
    Leader+?                this cheatsheet

  SESSION (resurrect — survives close/reboot)
    Leader+Shift+S          save current layout to disk
    Leader+Shift+R          restore a saved layout (fuzzy picker)
    (autosaves every 5 min + whenever a window loses focus/closes)

  Font: Ctrl+= / Ctrl+- / Ctrl+0   bigger / smaller / reset
]]

local function show_cheatsheet(window, pane)
  -- Write to $HOME (shared between the Flatpak sandbox and the host), NOT
  -- os.tmpname(). The GUI runs in the WezTerm Flatpak whose /tmp is private,
  -- but spawned panes run on the HOST via flatpak-spawn --host — so a sandbox
  -- /tmp path is invisible to the host `less` and the tab dies instantly.
  local path = (os.getenv("HOME") or "/tmp") .. "/.wezterm-cheatsheet.txt"
  local f = io.open(path, "w")
  if not f then
    window:toast_notification("WezTerm", "Cheatsheet: cannot write " .. path, nil, 3000)
    return
  end
  f:write(CHEATSHEET)
  f:close()
  window:perform_action(act.SpawnCommandInNewTab({
    args = { "bash", "-lc", "less -R " .. path .. "; rm -f " .. path },
  }), pane)
end

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

  -- Font size. `+` is Shift+`=` on US layouts, so a bare CTRL+`+` never
  -- matches (the real event is CTRL|SHIFT). Bind the physical `=` for the
  -- easy press and `+` under CTRL|SHIFT so both key combos work.
  { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "+", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = act.ResetFontSize },

  -- Launch menu (profile picker)
  { key = "p", mods = "CTRL|SHIFT", action = act.ShowLauncher },

  -- Quick Zellij in new tab
  { key = "z", mods = "CTRL|SHIFT", action = act.SpawnCommandInNewTab({
    args = { "zellij" },
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

  -- Window management (snap halves / maximize / restore / fullscreen).
  -- Super+Arrows mirror GNOME's tiling muscle memory; leader variants also below.
  { key = "LeftArrow", mods = "SUPER", action = act.EmitEvent("snap-left") },
  { key = "RightArrow", mods = "SUPER", action = act.EmitEvent("snap-right") },
  { key = "UpArrow", mods = "SUPER", action = act.EmitEvent("win-maximize") },
  { key = "DownArrow", mods = "SUPER", action = act.EmitEvent("win-restore") },
  { key = "Return", mods = "SUPER", action = act.ToggleFullScreen },

  -- Leader (Ctrl+a) chords — power-user layer, additive to everything above.
  -- Pass a literal Ctrl+a through to the shell (readline beginning-of-line).
  { key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
  -- Pane splits (mnemonic | and -) and management.
  { key = "|", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
  { key = "q", mods = "LEADER", action = act.CloseCurrentTab({ confirm = false }) },
  -- New OS window (Leader+Shift+N; bare Leader+n below makes a new workspace).
  { key = "N", mods = "LEADER|SHIFT", action = act.SpawnWindow },
  { key = "p", mods = "LEADER", action = act.PaneSelect({ alphabet = "asdfghjkl" }) },
  { key = "f", mods = "LEADER", action = act.Search("CurrentSelectionOrEmptyString") },
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  { key = " ", mods = "LEADER", action = act.QuickSelect },
  { key = "e", mods = "LEADER", action = act.CharSelect({ copy_on_select = true }) },
  -- Window management via leader (Vim hjkl + arrows both work).
  { key = "LeftArrow", mods = "LEADER", action = act.EmitEvent("snap-left") },
  { key = "RightArrow", mods = "LEADER", action = act.EmitEvent("snap-right") },
  { key = "h", mods = "LEADER", action = act.EmitEvent("snap-left") },
  { key = "l", mods = "LEADER", action = act.EmitEvent("snap-right") },
  { key = "m", mods = "LEADER", action = act.EmitEvent("win-maximize") },
  { key = "c", mods = "LEADER", action = act.EmitEvent("snap-center") },
  { key = "F", mods = "LEADER|SHIFT", action = act.ToggleFullScreen },
  -- Hide/show the tab bar from the keyboard (no hover-reveal exists in WezTerm).
  { key = "b", mods = "LEADER", action = act.EmitEvent("toggle-tab-bar") },
  -- Minimize the window (act.Hide). Super+H also minimizes via GNOME.
  { key = "h", mods = "SUPER", action = act.Hide },
  { key = ",", mods = "LEADER", action = act.Hide },
  -- Persistent sessions: attach the unix mux domain (survives GUI restart).
  { key = "u", mods = "LEADER", action = act.AttachDomain("unix") },
  -- Keyboard URL hints: label every link, type to pick, opens in browser.
  { key = "o", mods = "LEADER", action = act.QuickSelectArgs({
    label = "open url",
    patterns = { "https?://\\S+" },
    action = wezterm.action_callback(function(window, pane)
      local url = window:get_selection_text_for_pane(pane)
      if url and url ~= "" then wezterm.open_with(url) end
    end),
  }) },
  -- Toggle background transparency (0.92 <-> solid).
  { key = "O", mods = "LEADER|SHIFT", action = act.EmitEvent("toggle-opacity") },
  -- Enter modal resize mode (status bar shows RESIZE); hjkl resize, Esc exits.
  { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
  -- Agent layer (status bar shows AGENT). one_shot: fires a single key then
  -- exits, so it never traps you. Leader+a is free — only LEADER|CTRL+a is
  -- taken, for the literal Ctrl+a passthrough above.
  { key = "a", mods = "LEADER", action = act.ActivateKeyTable({
    name = "agent", one_shot = true, timeout_milliseconds = 2000,
  }) },
  -- App/command suggestions: one fuzzy switcher over launch-menu apps, open
  -- tabs, workspaces and the full command list. Type to filter ("app suggestions").
  { key = "Space", mods = "CTRL|SHIFT", action = act.ShowLauncherArgs({
    flags = "FUZZY|LAUNCH_MENU_ITEMS|TABS|WORKSPACES|COMMANDS",
  }) },
  -- Move between workspaces ("apps") with the keyboard.
  { key = "Tab", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },
  { key = "Tab", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(-1) },
  { key = "]", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },

  -- Workspaces.
  { key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
  { key = "n", mods = "LEADER", action = act.PromptInputLine({
    description = "New workspace name:",
    action = wezterm.action_callback(function(window, pane, line)
      if line and #line > 0 then
        window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
      end
    end),
  }) },

  -- Cheatsheet overlay (pages the full keymap in a new tab; q closes it).
  { key = "?", mods = "LEADER", action = wezterm.action_callback(show_cheatsheet) },

  -- Shell-integration nav (OSC 133): jump between shell prompts in scrollback.
  { key = "UpArrow", mods = "LEADER", action = act.ScrollToPrompt(-1) },
  { key = "DownArrow", mods = "LEADER", action = act.ScrollToPrompt(1) },
  -- Copy the LAST command's output (its semantic "Output" zone) to the clipboard.
  { key = "y", mods = "LEADER", action = wezterm.action_callback(function(window, pane)
    local zones = pane:get_semantic_zones("Output")
    if not zones or #zones == 0 then
      window:toast_notification("WezTerm", "No command output captured yet", nil, 2000)
      return
    end
    local text = pane:get_text_from_semantic_zone(zones[#zones])
    window:copy_to_clipboard(text or "", "ClipboardAndPrimarySelection")
    window:toast_notification("WezTerm", "Copied last command output", nil, 1500)
  end) },
}

-- Session persistence keybinds (resurrect.wezterm) — only wired if the plugin
-- loaded. Leader+Shift+S saves the current workspace layout (panes + cwds) to
-- disk; Leader+Shift+R opens a fuzzy picker of saved sessions to restore.
if ok_resurrect then
  table.insert(config.keys, {
    key = "S", mods = "LEADER|SHIFT",
    action = wezterm.action_callback(function(win, _pane)
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
      win:toast_notification("WezTerm", "Session saved", nil, 1500)
    end),
  })
  table.insert(config.keys, {
    key = "R", mods = "LEADER|SHIFT",
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, _label)
        local kind = string.match(id, "^([^/]+)")
        id = string.match(id, "([^/]+)$")
        id = string.match(id, "(.+)%..+$")
        local opts = { relative = true, restore_text = true }
        if kind == "workspace" then
          resurrect.workspace_state.restore_workspace(
            resurrect.state_manager.load_state(id, "workspace"), opts)
        end
      end)
    end),
  })
end

-- Copy the last command AND its output as a fenced markdown block — the shape
-- you actually want when pasting a failure into an agent. Uses OSC 133 semantic
-- zones (shell integration, on by default). Leader+y still copies output alone.
local function copy_last_exchange(window, pane)
  local inputs = pane:get_semantic_zones("Input")
  local outputs = pane:get_semantic_zones("Output")
  if (not inputs or #inputs == 0) and (not outputs or #outputs == 0) then
    window:toast_notification("WezTerm", "No shell zones captured yet", nil, 2000)
    return
  end
  local function last(zones)
    if not zones or #zones == 0 then return "" end
    return (pane:get_text_from_semantic_zone(zones[#zones]) or ""):gsub("%s+$", "")
  end
  local block = "```console\n$ " .. last(inputs) .. "\n" .. last(outputs) .. "\n```"
  window:copy_to_clipboard(block, "ClipboardAndPrimarySelection")
  window:toast_notification("WezTerm", "Copied last command + output", nil, 1500)
end

-- Whole scrollback to the clipboard — for handing an agent the full context of
-- a long run rather than just the last screenful.
local function copy_scrollback(window, pane)
  local text = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows) or ""
  if text == "" then
    window:toast_notification("WezTerm", "Scrollback is empty", nil, 2000)
    return
  end
  local _, lines = text:gsub("\n", "")
  window:copy_to_clipboard(text, "ClipboardAndPrimarySelection")
  window:toast_notification("WezTerm", "Copied " .. lines .. " lines of scrollback", nil, 1500)
end

-- Modal key-tables. Activated by leader chords above; status bar shows the mode.
config.key_tables = {
  -- Agent layer. Herdr owns agent DETECTION, state and notifications once you
  -- are inside it (docs/terminal/herdr.mdx); this table is only about starting
  -- an agent and feeding it terminal context — the emulator's own job.
  agent = {
    { key = "c", action = spawn_agent("claude") },
    { key = "s", action = spawn_agent("claude", true) },
    { key = "r", action = spawn_agent("claude --resume") },
    { key = "k", action = spawn_agent("claude --continue") },
    { key = "h", action = spawn_agent("herdr") },
    { key = "y", action = wezterm.action_callback(copy_last_exchange) },
    -- SHIFT is explicit: WezTerm reports Shift+y as key "Y" WITH mods=SHIFT, so
    -- a bare key = "Y" can fail to match. Matches how the shifted binds in
    -- config.keys above are written (LEADER|SHIFT for N / O / F).
    { key = "Y", mods = "SHIFT", action = wezterm.action_callback(copy_scrollback) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "q", action = "PopKeyTable" },
  },

  -- Resize the active pane with hjkl/arrows; Esc or Enter leaves the mode.
  resize_pane = {
    { key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
    { key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
    { key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
    { key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
    { key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 3 }) },
    { key = "RightArrow", action = act.AdjustPaneSize({ "Right", 3 }) },
    { key = "UpArrow", action = act.AdjustPaneSize({ "Up", 2 }) },
    { key = "DownArrow", action = act.AdjustPaneSize({ "Down", 2 }) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter", action = "PopKeyTable" },
  },
}

-- Mouse bindings
config.mouse_bindings = {
  { event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.OpenLinkAtMouseCursor },
  -- Copy-on-select: finishing a left-drag copies to clipboard + primary.
  { event = { Up = { streak = 1, button = "Left" } }, mods = "NONE",
    action = act.CompleteSelection("ClipboardAndPrimarySelection") },
  -- Middle-click pastes the primary selection (X11-style).
  { event = { Down = { streak = 1, button = "Middle" } }, mods = "NONE",
    action = act.PasteFrom("PrimarySelection") },
}

-- Hyperlinks: keep the built-in URL detection, then add a GitHub issue/PR
-- shorthand (owner/repo#123 → issue link). Kept narrow on purpose so plain
-- file paths like src/main aren't turned into bogus links.
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
  regex = [[\b([\w.-]+)/([\w.-]+)#(\d+)\b]],
  format = "https://github.com/$1/$2/issues/$3",
})

-- Misc
config.warn_about_missing_glyphs = false
config.check_for_updates = false
config.audible_bell = "Disabled"
config.exit_behavior = "Close"

return config
