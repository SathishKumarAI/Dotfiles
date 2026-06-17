# Worklog

## 2026-06-16 22:45 — Hover-reveal taskbar (Dash to Panel intellihide)

**Summary:** System-wide auto-hiding taskbar that reveals on mouse hover, for the
Rocky/GNOME 49 Wayland desktop.

**Changes:**
- `setup/install-hover-taskbar.sh` (new): installs Dash to Panel from EGO
  (version-matched, no sudo, idempotent — the existing `gnome-taskbar.sh` is
  pacman-only and won't run on Rocky) and writes intellihide dconf with
  `intellihide-use-pressure=false` so the panel reveals on plain hover, not a
  pressure push. Ran it — installed v73, dconf applied. Activates after logout.

**Decisions:** Dash to Panel (window-button taskbar) over Hide Top Bar — "tab
hover" implies window buttons, not just the top bar. Noted Hide Top Bar
(`hidetopbar@mathieu.bidon.ca`) as the top-bar-only alternative in the script.

**Follow-ups:**
- [ ] Log out / back in to load the taskbar.

## 2026-06-16 22:37 — WezTerm poweruser layer + niri-like tiling (PaperWM) + AATWS

**Summary:** Built out the WezTerm config (cheatsheet, shell integration,
quick-select), fixed the GNOME titlebar that returned with the Wayland switch,
and added a niri-style scrollable tiling setup + better app switcher for the
Rocky/GNOME 49 desktop.

**Changes:**
- `chezmoi/dot_wezterm.lua`:
  - `window_decorations` "RESIZE" → "NONE" — kills the GNOME server-side titlebar
    that Mutter drew once native Wayland was on. (Hover-reveal of the tab bar is
    impossible in WezTerm — no mouse API — so tab bar stays auto-hide-at-1 + Leader+b.)
  - `Leader+?` cheatsheet overlay — pages the full keymap in a new tab.
  - Shell integration: `Leader+Up/Down` jump prompt-to-prompt (ScrollToPrompt),
    `Leader+y` copies the last command's output via OSC 133 semantic zones.
  - `quick_select_patterns` — SHAs, IPv4, hex, paths, emails on `Leader+Space`.
- `chezmoi/dot_zshrc`: self-contained OSC 133 precmd/preexec hook (no system
  wezterm.sh on this box) so the prompt-jump + copy-last-output binds work.
- `setup/install-tiling.sh` (new): installs PaperWM (niri-like scrollable tiling)
  + AATWS (Advanced Alt-Tab) from extensions.gnome.org, version-matched to the
  running GNOME Shell. Idempotent, no sudo. Ran it — both on disk (PaperWM v148,
  AATWS v65); activate after logout.

**Decisions:**
- "niri-like" inside GNOME → PaperWM (scrollable columns), not standalone niri —
  keeps the GNOME 49 session, extensions, and AATWS. No compositor swap.
- Discovered the box is **GNOME Shell 49.4** (workspace CLAUDE.md said 47 — stale).
- EGO-download install (curl + `gnome-extensions install`) since neither ext is
  in dnf; verified both have GNOME-49 builds before writing the script.

**Follow-ups:**
- [ ] Log out / back in to activate PaperWM + AATWS.
- [ ] If PaperWM scrolling fights Tiling Assistant, `gnome-extensions disable tiling-assistant@leleat-on-github`.
- [ ] Update `~/coding/CLAUDE.md` GNOME version 47 → 49.

## 2026-06-16 22:24 — WezTerm fix: won't launch on Wayland (XOpenDisplay failed)

**Summary:** WezTerm failed to start — session is Wayland but config forced
`enable_wayland = false`, so it tried X11/XWayland and died with
`XOpenDisplay failed to open a display`. Flipped to native Wayland; launches clean.

**Changes:**
- `chezmoi/dot_wezterm.lua` — `config.enable_wayland = false` → `true`; updated
  the comment to note XWayland is unavailable in this session and document the
  `os error 71` fallback (front_end → "OpenGL" or upgrade wezterm).
- `chezmoi apply --force` — synced to `~/.wezterm.lua`.

**Decisions:** Native Wayland over X11 because XWayland is dead here (likely
Flatpak sandbox — fonts resolved from `/run/host/`), making the old
`enable_wayland=false` XWayland workaround a non-starter. Kept `front_end="WebGpu"`
(launched fine in test). Did not upgrade wezterm (`20240203`, old) — no sudo without ask.

**Follow-ups:**
- [ ] If Mutter explicit-sync crash (`Protocol error os error 71`) returns, switch `front_end` to `"OpenGL"` or upgrade wezterm.
- [ ] Benign `xkbcommon dead_hamza` Compose-file warnings on startup — system locale data, not config; ignore.

## 2026-06-16 20:36 — WezTerm: minimize keybind + persistent sessions + URL hints + copy-on-select + ligatures

**Summary:** Additive WezTerm round. Keyboard minimize, a persistent unix mux
domain, keyboard URL hints, copy-on-select / middle-click paste, opacity toggle,
and font ligatures. No decorations change (kept the clean borderless look).

**Changes (`chezmoi/dot_wezterm.lua`):**
- Minimize: `Super+h` / `Leader+,` → `act.Hide` (no titlebar buttons added).
- Persistent sessions: `config.unix_domains = {{name="unix"}}`; `Leader+u`
  attaches (`act.AttachDomain`); `wezterm connect unix` for persistent launch.
- Keyboard URL hints: `Leader+o` → `QuickSelectArgs` over `https?://` + callback `wezterm.open_with`.
- Opacity toggle: `toggle-opacity` event (0.92 ↔ 1.0), `Leader+Shift+O`.
- Copy-on-select (`CompleteSelection ClipboardAndPrimarySelection`) + middle-click
  paste (`PasteFrom PrimarySelection`) mouse bindings.
- Font ligatures: `harfbuzz_features = calt/liga/clig`.
- Docs: `docs/terminal/wezterm.mdx` keybind tables + persistent-sessions section.

**Decisions:**
- Minimize via keybind only (user choice) — `window_decorations="RESIZE"` kept,
  no Chrome-style buttons (would need TITLE or INTEGRATED_BUTTONS + fancy tab bar).
- unix mux left opt-in (not `default_gui_startup_args`) so the maximize-on-launch
  path stays simple and doesn't double-spawn windows.

**Verified:** `wezterm ls-fonts` valid; `chezmoi apply --force`; spawned a live new
window clean.

## 2026-06-16 20:19 — personalize.sh orchestrator + provisioning architecture doc

**Summary:** Added a single re-runnable "make this machine mine" script that
applies the post-install personalization the installers skip, and an
architecture doc explaining the whole provisioning model.

**Changes:**
- `setup/personalize.sh` (new, executable) — idempotent orchestrator:
  `chezmoi apply` → default-shell→zsh (`chsh`) → `atuin import` → GNOME
  key-repeat tuning → `validate-install.sh`. Flags: `--dry-run`, `--no-chsh`.
  Syntax + shellcheck clean.
- `docs/setup/architecture.mdx` (new) — provisioning model: three layers
  (packages=`setup/*.sh`, runtimes=mise, configs=chezmoi) + glue
  (`personalize.sh`), repos involved, mermaid flow, copy-paste fresh-machine
  run order, file map, idempotency notes.
- `docs/setup/installation-reference.mdx` — cross-link to the architecture doc.

**Decisions:**
- Kept personalization separate from `setup.sh` (installers) — different concern,
  re-run cadence, and failure model. `setup.sh` = packages; `personalize.sh` = config/glue.
- `chsh` is the only interactive step (needs password); `--no-chsh` to skip.

**Follow-ups:**
- [ ] User runs `bash setup/personalize.sh` (chsh step needs password in a real TTY).

## 2026-06-16 20:08 — Wire idle CLI tools (atuin/direnv/delta) + WezTerm new-window bind + docs

**Summary:** Machine efficiency pass. Three installed-but-unwired tools now
active (atuin history, direnv per-dir env, delta git pager). Added a WezTerm
leader bind for new windows. Documented atuin/direnv/delta with usage commands.
All applied via `chezmoi apply --force` and verified.

**Changes:**
- `chezmoi/dot_zshrc`, `chezmoi/dot_bashrc` — added `direnv hook` and
  `atuin init --disable-up-arrow` blocks (after fzf; up-arrow history-search kept).
- `chezmoi/dot_gitconfig` — delta as `core.pager` + `interactive.diffFilter` +
  `[delta]` (navigate/line-numbers/side-by-side).
- `chezmoi/dot_wezterm.lua` — `Leader+Shift+N` → `act.SpawnWindow` (new OS window).
- Docs (mdx, with command tables): new `docs/shell/atuin.mdx`,
  `docs/shell/direnv.mdx`; linked from `docs/shell/index.mdx`; refreshed
  `docs/modern-cli/index.mdx` (status missing→live, delta wired) and
  `docs/git/git-config.mdx` (delta pager notes).

**Decisions:**
- Edited chezmoi *source* then applied (rc files are chezmoi-managed) — never
  hand-edited `~/.zshrc` directly.
- `--disable-up-arrow` on atuin so it only owns Ctrl-R; existing prefix
  history-search on up-arrow preserved.
- delta `side-by-side = false` default (toggle per-taste).

**Verified:** delta renders a real diff (exit 0); direnv `version` ok; atuin wired
(its `stats` errors outside an initialized interactive shell — expected).

**Follow-ups (user, interactive):**
- [ ] `chsh -s "$(command -v zsh)"` — make zsh the default login shell (bash still default).
- [ ] `atuin import auto` — pull existing history into atuin.
- [ ] Optional: `gsettings ... keyboard delay 250 / repeat-interval 20` for snappier key-repeat.

## 2026-06-16 19:50 — WezTerm power-user + visualization upgrade (additive)

**Summary:** Big additive pass on the WezTerm config — visual polish + tmux-style
power-user layer + window management. Zero original settings/binds removed (0
deletions in the lua source). Applied via `chezmoi apply --force` and verified
live by spawning new windows against the running GUI.

**Changes:**
- `chezmoi/dot_wezterm.lua` (+266) —
  - Visuals: Catppuccin vertical gradient background; `inactive_pane_hsb` dimming;
    scrollbar; themed selection/cursor/split colors; visual-bell flash; cursor easing.
  - `format-tab-title` event: `index <proc-icon> title`, Mauve active tab, `[Z]` zoom marker.
  - `update-status` event: workspace pill (left) + `LEADER`/key-table badge (right).
  - Leader key `Ctrl+a` + binds: splits, zoom/close, pane picker, copy/quick-select,
    emoji, search, workspaces (switch/create/next); `resize_pane` modal key-table.
  - Window mgmt events: snap left/right half, maximize, restore, center via
    `gui_window` geometry API; bound to `Super+arrows` and leader.
  - `Ctrl+Shift+Space` fuzzy switcher (apps/tabs/workspaces/commands).
  - `Leader+b` toggle-tab-bar event (hover-reveal not supported by WezTerm).
  - GitHub `owner/repo#123` hyperlink rule.
- `docs/terminal/wezterm.mdx` (+50) — new Window/Leader keybind tables, Visuals section, Customization notes.
- `setup/install-wezterm.sh` (+13) — extended printed keybinding reference.

**Decisions:**
- Additive-only per user constraint: extended existing tables (`config.colors`),
  appended binds, occupied the unused `Ctrl+a` prefix — no clashes, nothing rebound.
- Background = subtle gradient (no image files); status bar = leader/mode + workspace
  only (no clock/host) per user's choices.
- Dropped an over-broad bare `owner/repo` hyperlink rule — it linkified every file path.
- Caught + fixed real bug during validation: `act.ShowLauncher` is a value, not
  callable → switched to `act.ShowLauncherArgs`. Validated with `wezterm ls-fonts`
  (show-keys ignores `--config-file`, so it's not a usable linter).

**Known limits (told the user):**
- Tab-bar mouse-hover reveal — no WezTerm API; gave `Leader+b` keyboard toggle.
- Snap-half may be overridden by GNOME Wayland compositor; `Super+arrows` mirror
  GNOME's own tiling as fallback.

**Follow-ups:**
- [ ] Commit the 3 changed files (still unstaged on `feat/productivity-workflow-installers`).
- [ ] Visually eyeball gradient/status-bar in a real window; tune gradient stops if heavy.

## 2026-06-16 00:47 — WezTerm fullscreen + keybinding audit + config bug fixes

**Summary:** WezTerm now launches maximized; audited all keybindings and fixed a
batch of validated config/doc/script bugs (terminal config divergence, broken
migration seeding, dead font-zoom binding, doc/config drift).

**Changes:**
- `chezmoi/dot_wezterm.lua` — added `gui-startup` handler to start maximized;
  fixed font-zoom keys (`Ctrl+=` plus `Ctrl+Shift++`, since `Ctrl++` never matches).
- `setup/chezmoi-migration.sh` — derive `REPO_ROOT` from script dir (was wrong
  hardcoded `~/coding/SathishKumarAI/Dotfiles`, all 3 fallbacks dead); seed
  `~/.wezterm.lua` from canonical config instead of the stale buggy copy.
- `setup/install-workflow-tools.sh` — yazi fallback `cargo yazi-build` (no such
  crate) → `pm_get yazi`; (earlier) added `gh_release_bin` prebuilt-binary helper.
- `md files/KEYBOARD-SHORTCUTS.md` — fixed Quick Reference Card (`Ctrl+Space`,
  `Super+Return`, dropped nonexistent VS Code binding), launch-menu default
  (Zsh not Bash), font keys, `Ctrl+Space` rofi-vs-zsh conflict note, maximize note.
- `.gitignore` (new) — Obsidian state, LibreOffice locks, OS cruft.
- `setup/verify-keyboard.sh`, `setup/remove-unwanted-apps.sh` (new) — libinput
  keycode verifier; flatpak/dnf app-removal script.

**Decisions:**
- Maximize (not `ToggleFullScreen`) on startup — keeps tab bar + window controls.
- Bugs validated, not guessed: `wezterm show-keys` confirmed the `Ctrl+Shift+D`
  scroll/split collision in the stale config and the font-key fix; `shellcheck
  -S warning` clean on all setup scripts.
- Left the stale `dotfiles/wizterm/.wezterm.lua` in place (README documents it as
  the original Windows config) but pointed migration away from it.

**Follow-ups:**
- [ ] Delete duplicate `dotfiles/wizterm/` to enforce single source of truth.
- [ ] Generate the cheatsheet from `wezterm show-keys` to stop doc/config drift.
- [ ] CI gate: `shellcheck` + `bash -n` + `wezterm show-keys` on PRs.
- [ ] Decide whether to track or ignore `.claude/` + `setup/.claude/` skill dirs.
