# Worklog

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
