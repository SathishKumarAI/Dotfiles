local wezterm = require("wezterm")

-- Helper function to find executable path (more reliable than hardcoding)
local function find_executable(possible_paths, fallback)
  -- Try to use environment variables if available
  local program_files = os.getenv("ProgramFiles")
  local program_files_x86 = os.getenv("ProgramFiles(x86)")
  
  -- Expand paths with environment variables
  local expanded_paths = {}
  for _, path in ipairs(possible_paths) do
    table.insert(expanded_paths, path)
  end
  
  if program_files then
    for _, path in ipairs(possible_paths) do
      local expanded = path:gsub("C:\\Program Files", program_files)
      if expanded ~= path then
        table.insert(expanded_paths, expanded)
      end
    end
  end
  
  if program_files_x86 then
    for _, path in ipairs(possible_paths) do
      local expanded = path:gsub("C:\\Program Files %(x86%)", program_files_x86)
      if expanded ~= path then
        table.insert(expanded_paths, expanded)
      end
    end
  end
  
  -- Try to check if the file exists
  for _, path in ipairs(expanded_paths) do
    local file = io.open(path, "r")
    if file then
      file:close()
      return path
    end
  end
  
  return nil
end

-- Helper function to find Git Bash path
local function find_git_bash()
  local possible_paths = {
    "C:\\Program Files\\Git\\bin\\bash.exe",
    "C:\\Program Files (x86)\\Git\\bin\\bash.exe",
  }
  
  local path = find_executable(possible_paths)
  if path then
    return { path, "--login", "-i" }
  end
  
  -- Fallback to PowerShell if Git Bash not found
  return { "powershell.exe", "-NoLogo" }
end

-- Helper function to find Conda path
local function find_conda()
  local possible_paths = {
    "C:\\ProgramData\\Anaconda3\\Scripts\\activate.bat",
    "C:\\Users\\" .. os.getenv("USERNAME") .. "\\anaconda3\\Scripts\\activate.bat",
    "C:\\Users\\" .. os.getenv("USERNAME") .. "\\miniconda3\\Scripts\\activate.bat",
  }
  
  local path = find_executable(possible_paths)
  if path then
    return { "cmd.exe", "/k", path }
  end
  
  return nil
end

-- Helper function to build launch menu with all profiles
local function build_launch_menu()
  local menu = {}
  
  -- Git Bash
  local git_bash_path = find_executable({
    "C:\\Program Files\\Git\\bin\\bash.exe",
    "C:\\Program Files (x86)\\Git\\bin\\bash.exe",
  })
  if git_bash_path then
    table.insert(menu, {
      label = "Git Bash",
      args = { git_bash_path, "--login", "-i" }
    })
  end
  
  -- WSL (check if wsl.exe exists - it's usually in PATH)
  if os.getenv("WSL_DISTRO_NAME") or os.getenv("WSLENV") then
    table.insert(menu, {
      label = "WSL",
      args = { "wsl.exe" }
    })
  else
    -- Try to find wsl.exe in common locations
    local wsl_paths = {
      "C:\\Windows\\System32\\wsl.exe",
      "C:\\Windows\\SysWOW64\\wsl.exe",
    }
    local wsl_found = false
    for _, path in ipairs(wsl_paths) do
      local file = io.open(path, "r")
      if file then
        file:close()
        table.insert(menu, {
          label = "WSL",
          args = { path }
        })
        wsl_found = true
        break
      end
    end
  end
  
  -- PowerShell
  table.insert(menu, {
    label = "PowerShell",
    args = { "powershell.exe", "-NoLogo" }
  })
  
  -- Conda
  local conda_path = find_conda()
  if conda_path then
    table.insert(menu, {
      label = "Conda",
      args = conda_path
    })
  end
  
  -- Zellij (if installed - usually in PATH)
  -- We'll add it if zellij command is available, but don't check file existence
  -- as it's typically installed via package manager and in PATH
  table.insert(menu, {
    label = "Zellij",
    args = { "zellij" }
  })
  
  return menu
end

local config = {
  -- Performance settings
  front_end = "WebGpu",   -- Use GPU for better performance
  max_fps = 120,          -- Set maximum FPS for smooth rendering
  animation_fps = 120,    -- Set FPS for animations to improve visual experience

  -- Font configuration with fallback
  font = wezterm.font_with_fallback({
    { family = "JetBrainsMono Nerd Font", weight = "Medium" },
    { family = "Cascadia Code", weight = "Regular" },
    { family = "Consolas", weight = "Regular" },
    "Courier New",
  }),
  font_size = 12.5,       -- Set font size for readability
  line_height = 1.15,     -- Set line height to improve spacing between lines

  -- Color Scheme (Catppuccin Mocha is dark, visually relaxing for long sessions)
  color_scheme = "Catppuccin Mocha",

  -- Window and UI Settings (clean layout for better workspace)
  window_background_opacity = 0.53,   -- Set window opacity for visual clarity
  window_padding = { 
    left = 12, 
    right = 12, 
    top = 10, 
    bottom = 10 
  },
  -- window_close_confirmation = 'AlwaysPrompt',

  -- Tab Bar Settings
  enable_tab_bar = true,  -- Enable tab bar to switch between tasks
  use_fancy_tab_bar = false,  -- Turn off fancy tab bar for a more minimalist look
  hide_tab_bar_if_only_one_tab = true,  -- Hide tab bar if only one tab exists
  tab_bar_at_bottom = true,   -- Place the tab bar at the bottom for better access

  -- Cursor Settings (Blinking block for better visibility)
  default_cursor_style = "BlinkingBlock",
  cursor_blink_rate = 650,  -- Set blinking rate for cursor

  -- Scrollback Lines (keeping history of your terminal output)
  scrollback_lines = 10000,

  -- Default shell to use Git Bash (with fallback detection)
  default_prog = find_git_bash(),

  -- Launch Menu: Multiple terminal profiles for easy access
  launch_menu = build_launch_menu(),
  -- Disable ALL close confirmations

  window_close_confirmation = 'NeverPrompt',
  -- Keybindings (Set useful keybindings for easy navigation)
  keys = {
    -- Pane splitting
    { key = "d", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "f", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
    
    -- Pane navigation (Vim-style)
    { key = "h", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
    { key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
    { key = "k", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
    { key = "j", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },
    
    -- Pane management
    { key = "Enter", mods = "CTRL|SHIFT", action = wezterm.action.TogglePaneZoomState },
    { key = "x", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
    
    -- Tab management
    { key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
    { key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
    { key = "Tab", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) },
    { key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action.ActivateTabRelative(-1) },
    
    -- Copy/Paste
    { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
    { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
    
    -- Font size adjustment
    { key = "+", mods = "CTRL", action = "IncreaseFontSize" },
    { key = "-", mods = "CTRL", action = "DecreaseFontSize" },
    { key = "0", mods = "CTRL", action = "ResetFontSize" },
    
    -- Launch menu for quick profile switching
    { key = "p", mods = "CTRL|SHIFT", action = wezterm.action.ShowLauncher },
    
    -- Zellij integration (launch Zellij session)
    { key = "z", mods = "CTRL|SHIFT", action = wezterm.action.SpawnCommandInNewTab({
      args = { "zellij" }
    }) },
  },

  -- Additional useful settings
  enable_wayland = false,  -- Disable Wayland on Windows
  warn_about_missing_glyphs = false,  -- Reduce warnings for missing glyphs
  check_for_updates = true,  -- Keep WezTerm updated
  check_for_updates_interval_seconds = 86400,  -- Check daily
  exit_behavior = "Close"





}

return config

