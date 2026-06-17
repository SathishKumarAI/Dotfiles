# Worklog

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
