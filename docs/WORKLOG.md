# Worklog

## 2026-06-22 22:41 — All-apps keybindings cheatsheet (MDX+PDF), CI gate, prompt template

**Summary:** Shipped a complete per-app keyboard cheatsheet (MDX + printable PDF)
covering every tool on the machine plus conflict/precedence logic, wired it into
the README/docs, added a CI lint gate, and authored a reusable prompt template to
regenerate it. Committed in 3 logical commits; push blocked on gh auth.

**Changes:**
- `docs/keybindings-cheatsheet.mdx` (new, 33 sections / 161 rows) — GNOME,
  PaperWM/AATWS/Tiling-Assistant/Dash-to-Panel, WezTerm direct + LEADER layer +
  launch profiles, Zellij, tmux, Neovim, lazygit, shell (fzf/atuin), Nautilus,
  plus a Conflict & precedence section (Ctrl+A three-layer chain, Super+arrow
  claimants, frequency-tier memorize order).
- `assets/keybindings-cheatsheet.pdf` (new, 421k) — rendered output.
- `setup/build-keybindings-pdf.sh` + `setup/md2html.py` (new) — MDX→HTML→PDF regen.
- `README.md` — link cheatsheet MDX + PDF, list PDF in assets tree.
- `docs/index.mdx`, `docs/keybindings.mdx` — cheatsheet + PDF links.
- `.github/workflows/ci.yml` (new) — `bash -n` + shellcheck on setup scripts +
  `wezterm ... ls-fonts` config validation.
- `docs/templates/prompts/build-keybindings-cheatsheet.md` (new) + templates README
  index entry — reusable prompt built on `prompt-skeleton.md`.
- `chezmoi/dot_bashrc`, `chezmoi/dot_zshrc` — add `~/.cargo/bin` to PATH.
- `setup/install-media-pdf.sh`, `setup/optimize-responsiveness.sh`,
  `setup/speedup-boot.sh` (new) — media/PDF toolchain + GNOME/boot tuning.
- `.gitignore` — ignore vendored `.claude/` + `setup/.claude/` skill dirs.

**Decisions:**
- Vendored Claude skill dirs (2.6M, impeccable + ui-ux-pro-max) → gitignored, not
  tracked (regenerable). Resolves the open track-vs-ignore follow-up.
- Stale `dotfiles/wizterm/` already gone — no delete needed.
- Cheatsheet sourced from real configs (90 wezterm binds in lua), not memory.

**Follow-ups:**
- [ ] `gh auth login` then push `docs/workspace-docs-library` + open PR (auth blocked the push).
- [ ] Eyeball the rendered PDF; tune `md2html.py` styling if layout heavy.

## 2026-06-18 13:00 — Moved workspace docs library into Dotfiles repo

**Summary:** Relocated `~/coding/docs/` content into `~/coding/Dotfiles/docs/` so the
whole docs library is version-controlled with the repo.

**Changes:**
- Merged into `Dotfiles/docs/`: `guides/`, `features/`, `templates/` (incl. ai-friendly-starter),
  and `README.md` → `LIBRARY-INDEX.md` (renamed; repo already had `index.mdx`).
- Older standalone worklog preserved as `Dotfiles/docs/WORKLOG-coding-archive.md` (live `WORKLOG.md` untouched).
- `~/coding/CLAUDE.md` — template location updated `~/coding/docs/templates/` → `~/coding/Dotfiles/docs/templates/`.
- `LIBRARY-INDEX.md` — fixed stale "not a git repo" note + self-path.

**Decisions:**
- Only collision was `WORKLOG.md` → archived, not overwritten (different/older history).
- Intended `~/coding/docs` → `Dotfiles/docs` symlink for path compatibility, but `rmdir`
  is blocked by the no-delete deny list; left `~/coding/docs` as an empty dir and pointed
  CLAUDE.md at the new path instead.

**Follow-ups:**
- [ ] (manual, needs your OK) recreate the symlink: `rmdir ~/coding/docs && ln -s ~/coding/Dotfiles/docs ~/coding/docs` — restores the old `~/coding/docs/...` paths.
- [ ] Commit the moved docs to the Dotfiles repo when ready.

## 2026-06-18 12:45 — Built workspace docs library + AI-friendly frontend starter

**Summary:** Created a reusable docs library under `~/coding/docs/` and a copy-me
frontend starter, all grounded in this machine's real state (HDD, miniforge python,
chezmoi divergence — verified this session, not guessed).

**Changes:**
- `~/coding/docs/README.md` (new) — index of the whole library.
- `~/coding/docs/guides/` (new):
  - `MACHINE-CHEATSHEET.md` — mise/chezmoi/dnf/flatpak/systemd/GNOME + modern CLI tool map + HDD reality.
  - `DEV-WORKFLOW.md` — project bootstrap, git/lazygit/gh, WezTerm/zellij/nvim, Python/conda, /document.
  - `CLAUDE-CODE-GUIDE.md` — skills, marketplaces, hooks, templates, context7 MCP.
  - `TROUBLESHOOTING.md` — HDD slowness, boot time, chezmoi diverged, mise "missing", WezTerm/Wayland, GNOME relogin.
- `~/coding/docs/templates/ai-friendly-starter/` (new) — `index.html` (semantic SSR-ready
  + OG + JSON-LD), `styles/tokens.css` (3-tier tokens + glass + reduced-transparency/
  motion/contrast fallbacks), `styles/main.css` (warm-editorial anti-slop aesthetic,
  staggered load, skip link, focus-visible), `llms.txt`, `robots.txt` (per-bot AI policy), `README.md`.

**Decisions:**
- Docs reflect verified machine facts (e.g. mise python shows "missing" because active
  python is miniforge) rather than generic advice.
- Starter aesthetic (Fraunces/Newsreader, rust/sage on warm paper) is a *demonstration*
  of §11 intentionality — README tells future-me to reskin per project, keep the structure.

**Follow-ups:**
- [ ] Version `~/coding/docs/` — `git init` or move into Dotfiles (it's untracked).
- [ ] Optional: preview the starter in a browser; reskin for a real project.

## 2026-06-18 11:55 — General UI/UX feature reference (web-sourced)

**Summary:** Built a general, vendor-neutral frontend UI/UX feature/pattern reference
(not app-specific) at `~/coding/docs/features/UI-UX-FEATURES.md`. Distinct from
FEATURES.md (which catalogs the user's own apps).

**Method:** Fanned out 7 web-research agents (WebSearch + WebFetch), one per UI/UX
domain, each returning a cited markdown section; synthesized into one doc with TOC +
consolidated sources. Authorities: NN/g, web.dev, MDN, WCAG/W3C ARIA APG, Material
Design, Apple HIG, Smashing, Laws of UX, USWDS, Refactoring UI.

**Sections:** Layout & Navigation · Forms/Input/Data Entry · Feedback & System State ·
Visual Design/Theming/Design Systems · Motion & Micro-interactions · Accessibility/
Responsiveness/Performance UX (incl. WCAG 2.2 + Core Web Vitals) · Common UI Components ·
Onboarding & Engagement · cross-cutting Laws of UX.

**Changes:**
- `~/coding/docs/features/UI-UX-FEATURES.md` (new) — ~9-section general reference checklist.

**Follow-ups:**
- [ ] Reuse as a design/review checklist for frontend repos (bujo, pickleball-shuffle, lona_access_ai, Personal-Portfolio).

**Update (12:30):** Used the `frontend-design` skill + web research to APPEND two more
sections (no deletions): §11 "Distinctive Design — Avoiding AI Slop" (bold aesthetic
direction, characterful type, conviction color, grid-breaking layout, high-impact motion,
atmospheric backgrounds, anti-slop blocklist) and §12 "Building AI-Friendly Sites"
(llms.txt/llms-full.txt, semantic HTML = agent legibility, JSON-LD/OpenGraph structured
data with honest caveats, SSR + Markdown variants for LLM extraction, MCP for agent
actionability, robots.txt AI-bot taxonomy + trade-offs, freshness/GEO, pitfalls). TOC → 12 sections.

**Update (12:10):** Added section 9 "Liquid Glass & Glassmorphism" (web-researched,
cited) — covers `backdrop-filter` CSS essentials, legibility scrims + WCAG contrast,
a11y fallbacks (`prefers-reduced-transparency`/`-motion`/`-contrast`, `forced-colors`),
GPU/INP performance budget (2–3 glass layers max, iOS fixed-position jank), `@supports`
progressive enhancement, material-level design tokens, and anti-patterns. TOC renumbered to 10 sections.

## 2026-06-18 11:25 — Consolidated FEATURES.md across all ~/coding apps

**Summary:** Read docs across the ~47 repos in `~/coding`, separated user-built apps
from cloned course/learning material, and produced a single consolidated
feature + changes reference at `~/coding/docs/features/FEATURES.md`. Covers **18 apps**.

**Method:**
- Surveyed all md/mdx docs (~1,700 files) + git remotes per dir to triage scope.
- Fanned out read-only Explore agents (1 per heavy app, grouped for small ones) to
  read each app's docs and return a structured `What it is / Stack / Features /
  Key changes` section; synthesized into one doc.
- Re-examined 6 borderline repos by reading SOURCE (not just docs): promoted
  Pediatrics, flashcards, loan to full entries; confirmed-skip Project-Med
  (template generator), Project_Lee (3rd-party HTML mockup), secret_valut (cred store).

**Apps documented (18):** bujo, Pickleball-Vision-LLM, Dotfiles, Job-Automations,
Nexus-Job-Automations, pickleball-shuffle, Dice_automation, resume-automation, RAG,
insta_reels_scrap, lona_access_ai, KickStarterFiles, rocky-dev-setup,
loan-default-prediction, Pediatrics, flashcards, loan.

**Changes:**
- `~/coding/docs/features/FEATURES.md` (new) — consolidated per-app features + changes.
- Excluded list documents what was skipped (course clones, forks, notes/empty) + why.

**Decisions:**
- Scope = user's own apps only (per user choice); excluded forked learning material
  even though forked under SathishKumarAI (remote alone can't distinguish).
- Source = docs only for the main pass; source-code read reserved for the 6 borderline repos.
- Job-Automations vs Nexus kept as separate entries (open question — Nexus may be successor).

**Follow-ups:**
- [ ] Confirm Job-Automations vs Nexus-Job-Automations: distinct, or merge as successor?
- [ ] `~/coding/docs/` is not a git repo — decide whether to version it (e.g. move into Dotfiles).
- [ ] Optional: script/skill to regenerate FEATURES.md as docs evolve.

## 2026-06-18 10:30 — Diagnosed machine slowness: I/O-bound on spinning HDD

**Summary:** Investigation only, no files changed. User asked what to clean to
make the box faster. Root cause is hardware: `/` and `/home` both live on one
7200rpm WD10EZEX HDD (`/sys/block/sda/queue/rotational = 1`); 12 cores idle,
11G RAM free → I/O-bound, not space- or CPU-bound. Disk is 14% full (741G free),
so cleaning files does almost nothing for speed.

**Findings:**
- Disk: `rl-home` XFS = 852G, 741G free; `/` (rl-root) only 70G. No user quota on `deva`.
- `/home/deva` = 95G used. Top dirs: Documents 37G, coding 16G, .var 9.9G,
  Downloads 7G, .cache 6.5G, .npm 3.0G, Trash 356M.
- Boot: `graphical.target` @47.7s; userspace total 4m40s (background jobs settling).
  Slowest units: plymouth-quit-wait 30s (harmless), docker 17s, plocate-updatedb 16s,
  containerd 13s, unbound-anchor 12s, disk-device detection 11s (mechanical HDD).
- Two fix-scripts already exist but were **never run** (still untracked):
  `setup/optimize-responsiveness.sh` (tames tracker3 + disables heavy/tiling extensions,
  no sudo) and `setup/speedup-boot.sh` (docker→socket-activation, kills plocate timer, sudo).

**Decisions:** Told user plainly that disk cleanup ≠ speed; the only real fix is an
SSD for `/` + `/home`. Did not run/delete anything (per "ask before delete" rule).

**Follow-ups:**
- [ ] Run `bash setup/optimize-responsiveness.sh` then log out/in (GNOME lag win).
- [ ] Run `sudo bash setup/speedup-boot.sh` (~46s off boot, effect next reboot).
- [ ] Optional space reclaim: `~/.cache` 6.5G, `npm cache clean --force` 3G, Trash 356M.
- [ ] Hardware: add SSD, move `/` + `/home` onto it — removes the bottleneck entirely.

## 2026-06-16 23:59 — validate-install: 15 "missing" tools were a PATH gap, not absent

**Summary:** `validate-install.sh` reported 15/45 FAIL (eza, delta, atuin, tldr,
xh, dust, hyperfine, procs, duf, csvlens, navi, watchexec, git-cliff, gh-dash,
croc). All 15 already on disk — 13 in `~/.cargo/bin`, croc in mise-go bin,
gh-dash as a gh extension. Root cause: `~/.cargo/bin` never on PATH, so the
validator (and interactive shells) couldn't see the rust tools. Fixed PATH; now
45 passed / 0 failed.

**Changes:**
- `chezmoi/dot_zshrc` + live `~/.zshrc` — added `$HOME/.cargo/bin` to `path` array.
- `chezmoi/dot_bashrc` + live `~/.bashrc` — guarded append of `~/.cargo/bin` to PATH.
- Branch scripts re-validated: `bash -n` (6 files) + `wezterm ls-fonts` (lua) +
  `shellcheck -S warning` (5 scripts) — all clean.

**Decisions:**
- No reinstalls — tools were present; only PATH was wrong. Avoided redundant
  cargo/go builds.
- Edited BOTH repo `chezmoi/dot_*` and live `~/.{bash,zsh}rc`: the live chezmoi
  source `~/.local/share/chezmoi` is diverged/broken (only holds `dot_config` +
  `private_dot_config`, `.config: inconsistent state`), so `chezmoi apply` errors
  and does not manage shell rc. Recorded to memory (chezmoi-source-diverged).

**Follow-ups:**
- [ ] Repair `~/.local/share/chezmoi` `.config` conflict; re-import shell rc into
      the real chezmoi source so `chezmoi apply` works again.
- [ ] After relogin, run `validate-install.sh` to confirm 45/45 in a fresh shell.
- [ ] `.claude/` + `setup/.claude/` are untracked — decide gitignore vs commit.

## 2026-06-16 22:52 — Main installer: wire in new GNOME scripts + sudo/user phases

**Summary:** Made the Rocky orchestrator actually install the new tiling + hover
taskbar, and split it into sudo (system/dnf) and user (no-sudo, ~/.local) phases
selectable from the command line.

**Changes:**
- `setup/setup-rocky.sh`: every step now tagged `run sudo …` or `run user …`.
  Added steps for `install-tiling.sh` (PaperWM+AATWS) and `install-hover-taskbar.sh`
  (Dash to Panel). New flags: `--user-only` / `--no-sudo` (run only no-sudo steps),
  `--sudo-only` (only dnf steps), default = all. Moved `install-workflow-tools.sh`
  to the sudo phase (it shells out to `sudo dnf`).
- `setup/setup.sh`: forwards `--user-only/--no-sudo/--sudo-only` to the per-OS
  orchestrator (safe empty-array expansion so no-arg runs don't break); dry-run
  now prints the phase next to each step.
- `setup/install-wezterm.sh`: `flatpak --user` (+ `--user` flathub remote) so the
  WezTerm step is genuinely sudo-free and belongs in the user phase.

**Decisions:** One file, two phases via a flag (not two separate scripts) — keeps
the step order/source of truth in one place. Verified: dry-run lists phases,
`--user-only` skips all sudo steps.

**Follow-ups:**
- [ ] Full run on a fresh box: `bash setup/setup.sh` (or `--user-only` without root).

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
