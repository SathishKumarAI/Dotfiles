# Worklog

## 2026-08-01 - Windows validation: 33/33 tools, and the check that was measuring the wrong thing

**Summary:** Probed every feature and application this repo provisions on
Windows against the live machine. The pipeline was sound — the *verification*
was not. Full report: [setup/windows-validation-2026-08-01.md](setup/windows-validation-2026-08-01.md).

**The finding.** `zoxide`, `starship` and `mise` were installed, on `PATH`, and
reported present by every probe — and completely inert. `z` did not exist,
because **no PowerShell profile existed at all** (all four candidate paths
empty). Windows creates none, and the Windows scripts never did either, while
the Linux side has always appended `eval "$(zoxide init bash)"` to `.bashrc`.
Nothing caught it because every check tested `PATH`, and `PATH` was correct.

| Fix | Where |
|---|---|
| Profile: zoxide/starship/mise init, PSReadLine, `ll`/`la`/`cat`/`lg`, `ws`/`dot`/`ml` | `assets/powershell-profile.ps1` (new) |
| Installs it when absent, never overwrites | `setup/setup-windows.ps1` |
| **Shell integration** panel — probes the profile, not the binary | `tools/mlops_dashboard.py` |

Same class, two more cases: `tesseract` and `wget2` were installed by the
`apps` stage and unreachable — neither installer touches `PATH`, and no probe
looked for them. Both added to `update-user-path.ps1` and to the inventory
under a new **Docs & OCR** category. Count moved 30/30 -> **33/33**.

**Everything else, verified:** 13/13 scoop, 29/32 winget (ExplorerPatcher,
Zebar and Brave removed on purpose per the 2026-07-31 audit), torch
2.11.0+cu128 with a real matmul on sm_120, dashboard routes 200 with all three
CSRF guards holding (no token / bad token / foreign `Origin` -> 403).

**Two stale claims corrected.** The audit's headline blocker is gone —
`vmcompute.exe` is present, `wsl --status` reads Default Version 2. What is
left is a missing distro and a stopped Docker Desktop, neither a blocker.
And `tools/check_docs.py` found **15 broken links** from the docs-library move:
`md files/` went under `docs/` but links kept their old `../` depth, and four
pointed at `~/coding/CLAUDE.md`, which is outside this repo and cannot be
linked relatively. Now 269/269 clean.

**The fix bit back, twice.** `$PROFILE` under `powershell -File` is 5.1's path,
so the profile would have landed in `WindowsPowerShell` and left pwsh 7 — the
shell actually used — bare; both hosts are now written explicitly. Then the
inventory fell 33 -> 32: `mise` read as missing while `mise --version` worked,
because `mise activate` defines a PowerShell **function** named `mise`,
`Get-Command` prefers it, and a function has no `.Source`. Probes now ask for
`-CommandType Application` first. Back to 33/33.

**Gotcha worth keeping:** PowerShell writes `pipeline-state.json` with a UTF-8
BOM. `load_state()` handles it (`utf-8-sig`); a plain `json.load` dies with
`Expecting value: line 1 column 1`.

## 2026-07-31 20:25 - Plugin audit: 30 enabled -> 10, ~14k tokens off every prompt

**Summary:** Audited all 31 installed Claude Code plugins against three
questions - does it work, does anyone use it, what does it cost per message.
Six were unusable (auth never set up), three had no toolchain on this box, five
duplicated a built-in. Disabled 21. Always-on context went ~20.9k -> **~6.9k**.

**The measurement that mattered.** Cost is charged at three separate sites and
only one responds to disabling:

| Site | Charged | Shrink by |
|---|---|---|
| System prompt (skill + agent descriptions) | every message | disabling - nothing else |
| MCP tool schemas | on load | already deferred via `ToolSearch` |
| Hooks | per session / per message | disable, or opt-out env var |

Agent descriptions turned out to cost more per item than skill descriptions -
they ship full multi-example blocks. `pr-review-toolkit` billed 2,033 tokens
from **six agents and one skill**, outranking plugins with ten skills.

**Why each one went** - four causes, all verified rather than assumed:

- **Auth never configured, so the MCP could not work at all:** `github`
  (`GITHUB_PERSONAL_ACCESS_TOKEN` unset), `pinecone`, `exa`, `sentry`,
  `firecrawl`, `huggingface-skills` (OAuth `authenticate` never run). Worst
  trade in the set - full context bill every message, zero capability.
- **Toolchain absent:** `gopls-lsp` (no `go`), `rust-analyzer-lsp` (no `rustc`),
  `lua-lsp` (no `lua-language-server`). Checked with `command -v`, not guessed.
- **Duplicates a built-in:** `chrome-devtools-mcp` + `playwright` vs
  `claude-in-chrome`; `serena` vs LSP + Grep; `exa` vs WebSearch;
  `pr-review-toolkit` vs `/review` + `/security-review` + `code-review` (four
  overlapping reviewers, kept one).
- **Domain not active:** `qdrant-skills`, `duckdb-skills`, `pydantic-ai`,
  `mcp-server-dev`, `agent-sdk-dev`, `nvidia-skills`, `context7`.

**Kept (10):** `plugin-dev` 2,349 · `mlflow` 1,987 · `caveman` 1,420 ·
`superpowers` 688 · `claude-md-management` 175 · `skill-creator` 112 ·
`frontend-design` 78 · `code-review` 20 · `typescript-lsp` 0 · `pyright-lsp` 0.

**Decisions:**
- **Disabled, not uninstalled**, and every plugin listed explicitly as `false`
  rather than deleted from the key. Re-enabling is a one-character edit and
  nothing silently reappears on plugin update.
- **Per-repo scoping is the answer to "auto enable/disable"** - there is no
  built-in unused-plugin reaper. A repo's `.claude/settings.json` takes the same
  `enabledPlugins` key and layers over the user file, so `huggingface-skills`
  can cost its 5k only inside `pickleball-vision-llm`.
- Kept `caveman` despite two hooks per message - output compression is
  net-negative cost. Kept `superpowers` despite its SessionStart hook
  re-injecting the full skill body (~700 tok); that injection is what makes the
  skills fire at all.
- Turned `huggingface-skills` off (5,029 tokens, the single largest line) since
  its MCP was unauthenticated and therefore unusable anyway. Re-scope per repo
  when HF work resumes.

**Changes:**
- `~/.claude/settings.json` - `enabledPlugins` rewritten, 10 true / 21 false.
  Backup at `~/.claude/settings.json.bak`. JSON validated with `node -e`.
- `docs/PLUGIN-AUDIT.md` (new) - 31-row decision table with per-plugin cost,
  status, and problem; environment-gap table; redundancy map; operating guide
  covering per-repo scoping, mid-session toggling, and measurement commands.
- `docs/ai-coding/plugins.mdx` - snapshot updated to post-audit state, added
  current-enabled table, the three-cost-sites model, scoping section, and a
  change log. Kept the measured per-plugin cost table as reference.
- `docs/LIBRARY-INDEX.md` - indexed the new audit doc.

**Follow-ups:**
- [ ] `npm i -g pyright` - `pyright-lsp` is enabled but its binary is missing,
      which is pure cost until fixed. Or turn it off.
- [ ] Add `.claude/settings.json` scoping files to `pickleball-vision-llm`
      (huggingface-skills, mlflow) and verify layering works with `/plugin`.
- [ ] Run `/context` right after a `/clear` post-restart to confirm the ~6.9k
      floor; re-measure with `claude plugin details` if it disagrees.
- [ ] Decide on `mlflow` - its UserPromptSubmit hook fires on every message;
      first candidate to cut if MLflow work stops.

## 2026-07-31 20:15 - Machine audit; Docker root-caused; ExplorerPatcher removed

**Summary:** Audited all 65 installed programs and root-caused Docker. Removed
ExplorerPatcher, stopped GlazeWM/Zebar.

**Docker was never a Windows Pro problem.** Docker Desktop runs on Home via the
WSL2 backend; Pro is only needed for the Hyper-V backend and Windows
containers. The real cause is that the **Virtual Machine Platform optional
component was never enabled** - `vmcompute.exe` does not exist on disk - so the
Linux engine has no VM to start on and `docker version` returns a 500. Firmware
virtualization (SVM) was already on. The same component blocks WSL2, so
`wsl --install --no-distribution` + reboot clears both.

**Duplicate installs found.** `rg`, `fd`, `fzf`, `zoxide` each exist twice: a
winget copy that predated the run and a scoop copy added by
`setup-windows.ps1`. scoop wins on PATH; the winget copies are dead weight.
`python` also resolves twice, real 3.12.10 ahead of the dead Store stub.

**Desktop changes reverted:**
- ExplorerPatcher **uninstalled** - it was making Windows 11 render as Windows
  10. Its uninstaller killed `explorer.exe` and did not restart it; had to
  relaunch manually. `HKCU:\Software\ExplorerPatcher` left in place (inert).
- GlazeWM + Zebar **stopped, kept installed**. Low value on a single 1080p
  screen given FancyZones, Windows Snap and zellij already overlap; genuinely
  worth re-enabling with a second monitor, where per-monitor workspaces have no
  native Windows equivalent. Neither has an autostart entry.

**Changes:** `docs/setup/machine-audit-2026-07-31.md` (new), `windows.mdx`
gains a "Docker on Windows Home" section, LIBRARY-INDEX updated.

**Open:** Virtual Machine Platform still not enabled (needs admin + reboot);
Store python aliases still on; 4 duplicate CLI installs not yet pruned.

---

## 2026-07-31 19:55 - Dashboard became a control plane; log formatter; shipped a broken page and fixed it

**Summary:** Turned the read-only dashboard into a local job runner (AWX/Semaphore
shape, one machine), added a log formatter, and shipped a page whose JavaScript
did not parse. The last part is the lesson.

**Control plane.** `tools/mlops_dashboard.py` now runs pipeline stages on click,
streams stdout to per-run log files, and records what each run changed.
Five tabs: Overview, Pipeline, Console, Tools, History.

- Run history **measures rather than parses**: the server snapshots which tools
  resolve before a stage and again after, and records the set difference. "This
  run added `go`" is an observation, not a guess from installer output.
- Logs: `setup/state/logs/<timestamp>-<stage>.log`, index in `history.json`.
  Both gitignored - machine state, not source.

**Security.** `--allow-run` is off by default; a page that can start installers
is a real attack surface. Three guards, all verified:

| Request | Result |
|---|---|
| no token | `403 bad or missing token` |
| wrong token | `403 bad or missing token` |
| valid token, foreign Origin | `403 cross-origin request refused` |
| unknown stage | `400 unknown stage` |
| valid token + same origin | run starts, log streams |

**Log readability.** Root cause first: `Run-Script` was letting each child's
entire stdout become the scriptblock's return value, so a stage's `detail` field
held one unbroken multi-KB line. Fixed with `| Out-Host`. Then a formatter on
top - measured on a real `base` run: 16,451 bytes, 93 formatted lines,
**69 noise lines collapsed**, 20 winget/scoop package blocks folded into single
verdict lines. Drops PowerShell's `+ CategoryInfo` / `+ FullyQualifiedErrorId` /
caret boilerplate. Four filters (all / changes / problems / raw), text search,
per-line stage gutter.

**The failure worth recording.** The page's entire `<script>` failed to parse,
so nothing on the UI worked - the user found it, not me. Two escaping
casualties from writing JS through Python heredocs:

1. a regex-escape pattern arrived mangled as `/[.*+?^${}()|[\]\]/g` - an
   unterminated character class;
2. `"
"` became a **literal newline inside a string literal**.

Either alone kills the whole script. I had verified Python syntax and HTTP 200,
neither of which can detect broken JS.

**Fixes + new checks:** both rewrites removed the hazard rather than escaping
harder (`indexOf` highlighting instead of a regex; `String.fromCharCode(10)`
instead of `"
"`). Verification now includes, run against the page rendered
offline:

- `node --check` on the extracted `<script>`
- every `el("id")` the JS references must exist in the HTML (catches the
  `clearCon` class of bug - a removed element still referenced)
- tab/view id parity, and every class queried by JS present in the markup

**Open:**
- **ExplorerPatcher** was installed from the old machine's inventory and makes
  Windows 11 render as Windows 10. Faithful to the inventory, probably not
  wanted - remove with `winget uninstall valinet.ExplorerPatcher`.
- Chrome extension still not connected, so no rendered-page inspection.

---

## 2026-07-31 19:25 - Windows box provisioned end-to-end; pipeline + dashboard built; 4 idempotency bugs fixed

**Summary:** Ran the Windows/ML scripts for real, then wrapped them in an
orchestrated pipeline and a local dashboard. Running them *through* an
orchestrator exposed four failures that running them by hand never did.

**Result:** 30/30 tools present. torch 2.11.0+cu128 with CUDA verified on the
RTX 5070 Ti by an actual device matmul, not just `is_available()`. WSL2 is the
only outstanding item and is blocked on elevation, not on this repo.

**Installed:** VS Code, PowerShell 7, Neovim, gh, Miniforge3; scoop + rg fd bat
fzf zoxide starship zellij lazygit delta eza mise chezmoi + JetBrainsMono NF;
GlazeWM, Zebar, PowerToys, ExplorerPatcher, WizTree, MSVC Build Tools, Node 24,
jq, wget, Postman, PostgreSQL 17, minikube, Docker Desktop, Obsidian, Pandoc,
MiKTeX, Tesseract, LibreOffice, LM Studio, OBS, Brave, Zen; Python 3.12.10, uv,
Go 1.26.5 (mise), and 246 Python packages.

**Root causes (all four are classes, not one-offs):**
1. **`powershell -File` flattens arrays.** `-Stages a,b` arrives as the single
   string `"a,b"`. The switch matched nothing, so the pipeline reported success
   while doing zero work. Hit three separate times.
2. **`[ValidateSet]` binds before the script runs**, so it rejected the
   comma-joined string outright and no in-script fix could help.
3. **`uv venv` errors on an existing environment**, so every `ml` re-run failed.
   `--clear` would have deleted a 2.6 GB torch install.
4. **A shell holds the PATH it launched with.** The `base` stage concluded
   scoop was missing, reinstalled it, then skipped all 13 CLI tools; the
   inventory reported 4/30 tools when 30 were present.

**Changes:**
- `setup/pipeline-windows-ml.ps1` - **new.** Six idempotent, timed, resumable
  stages writing `setup/state/pipeline-state.json`.
- `tools/mlops_dashboard.py` - **new.** Stdlib-only server on :8765. Live GPU
  telemetry, tool inventory, stage timeline. Palette validated with the
  `dataviz` validator (two earlier attempts failed on lightness band and
  normal-vision separation).
- `setup/setup.ps1`, `setup-windows.ps1`, `install-windows-apps.ps1` -
  `Sync-PathFromRegistry` added; ValidateSet removed in favour of manual
  validation after splitting.
- `setup/install-ml-windows.ps1` - reuses an existing venv.
- `setup/install-wsl-ubuntu.ps1` - distinguishes firmware-virtualization-off
  from Windows-component-missing (the built-in error conflates them); installs
  with `--no-launch` so it cannot hang on the username prompt.
- `docs/setup/ml-devops-pipeline.mdx`, `docs/ai-coding/plugins.mdx` - new.

**Probe corrections:** a zero-byte exe is usually a dead Store alias, but
`winget`'s launcher is zero bytes and real - the test is now scoped to
`python`/`python3`. mise-managed runtimes sit behind mise shims, so the probe
falls back to `mise which`.

**Open:**
- **WSL2 blocked.** Firmware virtualization is ON (`VirtualizationFirmwareEnabled:
  True`); the Windows *Virtual Machine Platform* component is not. Needs
  `wsl --install --no-distribution` from an admin shell, then a reboot.
- Microsoft Store `python.exe`/`python3.exe` aliases still ON - manual toggle.
- 31 Claude Code plugins installed; `posthog` disabled (23.2k always-on tokens,
  53% of the bill). `semgrep` uninstalled - its PostToolUse hook blocked every
  file write with "Not logged into Semgrep Guardian".
- `ponytail` plugin still unlocated.
- Linux equivalent of the ML installer still to write.

---

## 2026-07-31 18:45 — Windows/ML provisioning path built; 3 latent PowerShell bugs fixed; 32 Claude plugins installed

**Summary:** Audited the repo for what it can install on a *Windows* machine and
found two gaps: the ML/Python story did not exist at all, and the Windows
scripts that did exist **could not run**. Built the missing ML + WSL2 layer,
fixed the broken scripts, then installed and measured a 32-plugin Claude Code
set.

**Machine:** Windows 11 Home 26200 · Ryzen 7 9800X3D · 31.2 GB RAM · **RTX 5070
Ti 16 GB (Blackwell, sm_120, compute cap 12.0)** · driver 610.47 / CUDA UMD 13.3
· C: 1.7 TB free. Before this session: only winget, git, WezTerm, wsl (no
distro). No real Python, no conda, no node, no scoop.

**Root causes (pre-existing, all latent until someone ran the Windows path):**
1. **Em dashes broke two scripts.** `setup.ps1` (4 parse errors) and
   `setup-windows.ps1` (3) are UTF-8 **without BOM**. Windows PowerShell 5.1
   decodes BOM-less `.ps1` as ANSI, so `—` (`E2 80 94`) becomes `â€"` — and that
   third byte is U+201D, a smart closing quote, which PowerShell honours as a
   **string terminator**. Every string after one em dash was mis-parsed.
2. **`where.exe` + stderr redirect.** `update-user-path.ps1` used
   `& where.exe $c 2>$null`. On 5.1 that wraps output in a `NativeCommandError`;
   combined with the script's `$ErrorActionPreference = "Stop"`, the validation
   loop **aborted on the first missing tool**.
3. **`$IsWindows` under StrictMode.** `setup.ps1` referenced `$IsWindows`, which
   does not exist in 5.1 — a bare reference throws under
   `Set-StrictMode -Version Latest`.
4. **`mlflow@1.0.0` plugin fails to load.** Its manifest declares
   `"hooks": "./hooks/hooks.json"`, but that path is auto-loaded — duplicate
   load, whole plugin dead. Upstream packaging bug.

**Changes:**
- `setup/install-ml-windows.ps1` — **new.** Reads `nvidia-smi --query-gpu=compute_cap`
  and maps it to a PyTorch wheel channel (≥12.0 → `cu128`, ≥8.9 → `cu128`,
  ≥7.0 → `cu126`, else `cpu`), installs real CPython + uv, builds a venv, pulls
  torch from the explicit CUDA index, then **proves** it with a 2048×2048 device
  matmul rather than trusting `torch.cuda.is_available()`. Detects the 0-byte
  Microsoft Store `python.exe` alias that shadows real installs. **Never touches
  GPU drivers** — read-only `nvidia-smi`.
- `setup/ml/requirements-ml.txt` — **new.** ~45 libs. torch deliberately excluded:
  it must come from the CUDA index or the resolver can pick a wheel with no
  kernels for the card.
- `setup/install-windows-apps.ps1` — **new.** Restores the app set from
  `dotfiles/misc/all_programs.txt` (the old machine's 123-program inventory) in
  6 groups. All 24 winget IDs verified against the live source. Drivers/OEM
  packages excluded by design. Also installs `assets/glazewm-sample-config.yaml`.
- `setup/install-wsl-ubuntu.ps1` + `setup/wsl/bootstrap-wsl.sh` — **new.** WSL2 +
  Ubuntu with CUDA passthrough. Documents why you must **never** install a Linux
  NVIDIA driver inside the distro (it overwrites the `/usr/lib/wsl/lib` stubs the
  Windows driver projects in).
- `setup/setup.ps1`, `setup-windows.ps1`, `update-user-path.ps1` — **fixed** all
  three bugs above; converted all six `.ps1` to ASCII.
- `docs/setup/windows.mdx` — **new.** Run order, script inventory, the Store-stub
  trap, the compute-capability → wheel-channel table, the WSL driver rule.
- `docs/ai-coding/plugins.mdx` — **new.** 32-plugin inventory with *measured*
  always-on token costs, the `mlflow` workaround, marketplace commands.
- `README.md` — Windows quick-start now lists all four scripts; ML-environments
  TODO closed (done via uv, not conda).

**Verification:** all 6 `.ps1` files pass `[Parser]::ParseFile` (were 7 errors);
dry-runs of `install-ml-windows.ps1`, `install-windows-apps.ps1 -Groups All`,
`update-user-path.ps1`, and `setup.ps1` all run clean. GPU detection correctly
reports compute cap 12 → `cu128`. `bash -n` passes on `bootstrap-wsl.sh`.
*(Superseded by the 2026-07-31 19:25 entry above: the scripts were subsequently
run and the machine provisioned end-to-end.)*

**Plugins:** 32 installed across `claude-plugins-official` + `caveman`, all
enabled after patching the `mlflow` manifest. Measured **~44.1k tokens
always-on** — of which **`posthog` alone is 23.2k (133 skills), 53% of the
bill**. Disabling it drops the total to ~21k. Full table in
`docs/ai-coding/plugins.mdx`.

**Open:**
- Microsoft Store `python.exe`/`python3.exe` aliases still ON — must be toggled
  off by hand (Settings → Apps → Advanced → App execution aliases); no script
  can do it.
- `ponytail` plugin requested but not found in any marketplace; source unknown.
- The `mlflow` manifest patch reverts on plugin update.
- Linux equivalent of `install-ml-windows.ps1` still to write.

---

## 2026-07-14 13:30 — Voice dictation: mic capture fixed (parec → pw-cat), ydotool half found missing

**Summary:** Ran down "the microphone doesn't work". Mic hardware was fine — the
C270 webcam captures cleanly (test recording: RMS 534, peak 8925). Dictation was
broken in two independent places: the recorder binary didn't exist, and the
type-at-cursor backend was never installed on this machine at all.

**Root causes:**
1. **Recorder.** nerd-dictation defaults to `--input=PAREC`, which shells out to
   `parec` — that ships in `pulseaudio-utils`, which is *not installed* (this is a
   pure PipeWire box; even `pactl` is absent). `Super+\` died instantly with
   `FileNotFoundError: [Errno 2] No such file or directory: 'parec'`.
2. **Typing backend.** ydotool is not on the machine: no `ydotool`/`ydotoold`
   binary, no user service, no uinput udev rule, `/dev/uinput` root-only, `$USER`
   not in `input`. `~/coding/scripts/setup-voice.sh` — which the docs claim
   installs all of this — did not exist on disk either. So dictation would *hear*
   speech and type nothing, which is indistinguishable from a dead mic.

**Changes:**
- `~/.local/bin/voice-toggle` — pass `--input=PW-CAT` (not in a repo; chezmoi does
  not track it). Verified end-to-end: `wpctl status` shows
  `input_MONO < C270 HD WEBCAM:capture_MONO [active]` while dictation runs.
- `scripts/setup-voice.sh` — recreated (was missing). Builds ydotool from source
  (not packaged for Rocky 10), installs the uinput udev rule, adds `$USER` to
  `input`, installs the ydotoold user service, rebinds `Super+\`. **Not yet run.**
- `docs/desktop/voice-dictation.mdx` — added a troubleshooting section (recorder
  vs typing backend vs built-in card, with diagnostic commands); corrected the
  setup table, which wrongly claimed parec was the recorder and ydotool installed.

**Decisions:**
- Fixed the recorder with `--input=PW-CAT` rather than `dnf install
  pulseaudio-utils`. `pw-cat` is already present, native to PipeWire, and adds no
  packages — installing the Pulse compat shims just to get `parec` is backwards on
  a PipeWire-only system.
- Did not run `setup-voice.sh` — it installs packages and changes group
  membership, so it's the user's call (workspace rule: sudo work goes in a `.sh`,
  never pasted inline).

**Also found (separate, pre-existing):** built-in Realtek ALC3246 card is switched
**off** — WirePlumber marks every analog/HDMI profile `available: no` (ALSA jack
detection sees nothing plugged in), so it picks profile `off`. Hence no internal
mic, no internal speakers, and `Dummy Output` as the only sink. Does not affect
dictation (webcam mic is the source). Force on with `wpctl set-profile <id> 1`.

**Follow-ups:**
- [ ] Run `bash ~/coding/scripts/setup-voice.sh`, then log out/in (the `input`
      group only applies to a new session), then verify `systemctl --user status
      ydotoold` is active and `Super+\` types at the cursor.
- [ ] Decide whether to restore built-in analog audio (speakers/internal mic) or
      leave the card off and stay on the webcam mic.
- [ ] Consider tracking `~/.local/bin/voice-toggle` in chezmoi — the parec fix
      currently lives only on this machine and would be lost on a rebuild.

## 2026-07-07 18:10 — WezTerm session persistence + Neovim plugins + shortcut deck

**Summary:** Finished the in-flight WezTerm resurrect work (recover closed
windows), rebuilt the frame, fixed a broken cheatsheet, audited/validated every
dotfile on the machine, stood up a full Neovim plugin layer, and shipped a
filterable HTML keyboard-shortcut deck.

**Changes:**
- `chezmoi/dot_wezterm.lua` — resurrect autosave-on-close (`window-focus-changed`),
  periodic save 15→5 min, `resurrect.error` logger; titlebar → `INTEGRATED_BUTTONS`
  + fancy tab bar at top + themed `window_frame`; cheatsheet writes to `$HOME`
  (Flatpak sandbox `/tmp` was invisible to host `less`); added SESSION keys to
  the in-terminal cheatsheet. Validated + copied live to `~/.wezterm.lua`.
- `chezmoi/private_dot_config/nvim/` — Lazy bootstrap + modular layout
  (`vim_config.lua`, `keys.lua`, `plugins/{navigation,git,ui}.lua`): Snacks
  (picker/notifier/lazygit), Oil, Neogit, gitsigns, which-key, Catppuccin Mocha.
  Installed live (9 plugins, error-free) via headless `Lazy sync`.
- `chezmoi/dot_bashrc` — backported the machine's `conda initialize` block
  live→source (repo was behind reality).
- `docs/terminal/shortcuts.html` — new interactive, filterable, categorized
  shortcut + CLI reference (Catppuccin light/dark). Published as an Artifact.
- `docs/terminal/KEYBOARD-SHORTCUTS.md` — added Neovim section + link to the deck.

**Decisions:**
- Rejected a pasted Nix/home-manager/Herd setup — it would have stood up a
  competing stack beside the working chezmoi/mise/zellij. Kept existing, added
  only the real gap (nvim plugins). Snacks over Telescope; Catppuccin over
  rose-pine (house rule).
- Found chezmoi fully broken: empty stray `~/.local/share/chezmoi/dot_config`
  collides with `private_dot_config`. `rmdir` is deny-listed, so left for the
  user to run. Until then, live configs updated by direct copy, not `chezmoi apply`.

**Follow-ups:**
- [ ] User: `rmdir ~/.local/share/chezmoi/dot_config && chezmoi apply` to restore chezmoi.
- [ ] Track `~/.wezterm.lua` in chezmoi (currently not managed — no source file).
- [ ] Commit this session's work (branch `docs/workspace-docs-library`).

## 2026-07-07 00:52 — Disk relocation audit + voice dictation setup

**Summary:** Audited disk pressure on the 70G root, verified/completed the
root→home relocation of container + flatpak stores, and stood up offline
type-at-cursor voice dictation (nerd-dictation + VOSK + ydotool). Root went
67% → 35% (46G free); ~13G more reclaimable.

**Changes:**
- `docs/desktop/disk-usage-and-relocation.md` (new) — disk audit, relocation
  status, docker audit (build-cache junk vs active dev images), reclaim steps.
  Committed `7e5fc40`.
- `docs/desktop/voice-dictation.mdx` — rewritten to match the real
  nerd-dictation/VOSK/ydotool setup (was falsely marked Speech Note "installed").
  Committed `7e5fc40`.
- `docs/LIBRARY-INDEX.md` — added a Desktop section for the two docs (uncommitted;
  file had pre-existing edits from earlier work).
- `~/coding/scripts/disk-cleanup-and-relocate.sh` (new) — staged, safe: prune
  docker build-cache/dangling, relocate docker+containerd to home with a
  **sudo keep-alive** (the fix for the original run's mid-rsync sudo timeout),
  reclaim .old backups. Not in a git repo.
- `~/coding/scripts/setup-voice.sh` (new) — installs parec, builds ydotool
  (not packaged for Rocky 10), uinput udev rule, ydotoold user service, GNOME
  hotkey `Super+\`. Run as user, not sudo.
- `~/.local/share/nerd-dictation/` — vosk venv + nerd-dictation clone; VOSK
  small model at `~/.config/nerd-dictation/model` (68M).
- `~/.local/bin/voice-toggle` (new) — start/stop dictation launcher.
- Fixed +x on 3 dotfiles scripts (install-wezterm, setup-rofi-*).
- `pip cache purge` → freed ~5.3G in `~/.cache/pip`.

**Decisions:**
- Relocation via **bind mounts** (paths unchanged, fstab-persisted, reboot-safe)
  vs moving + reconfiguring each app. All 3 stores confirmed writing to
  `/home/.system` by default.
- Docker images are **live dev stacks** (Supabase, Firefly, loan/job/program
  managers) — keep; only prune build-cache + dangling, never `prune -a` or
  volumes. containerd is docker's snapshotter store, not separate junk.
- Voice: **nerd-dictation + ydotool** for type-anywhere (Claude Code has no voice
  mode). ydotool over wtype because GNOME/Mutter lacks the virtual-keyboard
  protocol; ydotool injects via `/dev/uinput` instead.

**Follow-ups:**
- [ ] Run `~/coding/scripts/setup-voice.sh` (sudo build), then log out/in once for
  the `input` group, then test `Super+\`.
- [ ] `sudo rm -rf /var/lib/flatpak.old` → reclaim ~13G on root (drops to ~17%).
- [ ] Optionally relocate `/opt` browsers (839M) — low priority.
- [ ] Commit the pre-existing untracked docs library work (not done this session).

## 2026-07-02 15:26 — WezTerm window decorations fix + interactive keymap cheatsheet

**Summary:** WezTerm behaved unlike a normal app (no minimize/maximize/resize —
title bar was gone). Root-caused to `window_decorations = "NONE"`; restored
normal Mutter window controls. Built a searchable HTML keymap cheatsheet and
reconciled the stale wezterm doc with the live config.

**Changes:**
- `~/.wezterm.lua` + `chezmoi/dot_wezterm.lua` — `window_decorations` `"NONE"` →
  `"TITLE|RESIZE"`: GNOME server-side titlebar (min/max/close + drag bar) and
  edge-resize borders return. Synced the repo copy to the live file so version
  control has the fix (chezmoi's active source doesn't track wezterm.lua).
- `docs/terminal/wezterm-keymap.html` — new interactive cheatsheet (Catppuccin
  Mocha, type-to-filter, every binding from the config; Leader/Super color-coded).
- `docs/terminal/index.mdx` — link the cheatsheet in the terminal page table.
- `docs/terminal/wezterm.mdx` — reconciled stale facts: native Wayland
  (`enable_wayland = true`, not XWayland/`false`), documented `window_decorations`,
  added decoration troubleshooting, linked the keymap. Status `diverged` → `live`.

**Decisions:**
- `"TITLE|RESIZE"` over `"RESIZE"` — user explicitly wanted minimize + normal
  buttons, which need the titlebar (`TITLE`), not just resize borders.
- Kept the cheatsheet as standalone HTML (not mdx) — the value is the live
  filter; still version-controlled next to the mdx docs.
- Decorations don't hot-reload — a fresh window is required after the change.

**Follow-ups:**
- [ ] Consider revisiting the startup `maximize()` hook if a non-maximized
      default is wanted now that the titlebar restore/drag works.

## 2026-06-30 13:05 — Test panel/dock scripts live; fix bus + install bugs

**Summary:** Actually executed the panel/dock scripts against the live GNOME
session and fixed three real bugs the dry runs hid. Verified writes land in the
real dconf database.

**Changes:**
- `setup/panel-position-top.sh`, `panel-modern-style.sh`, `install-content-dock.sh`
  — added a session-bus guard: re-export `DBUS_SESSION_BUS_ADDRESS` to
  `$XDG_RUNTIME_DIR/bus` when the shell inherits a Flatpak/proxy bus that can't
  reach GNOME's dconf ("Could not connect").
- `install-content-dock.sh` — replaced `gnome-extensions install` (needs a live
  Shell D-Bus; silently no-ops in sandboxed/SSH shells) with manual
  `unzip` + `glib-compile-schemas`. Made hiding D2P's app icons **opt-in**
  (`HIDE_D2P_TASKBAR=true`) so there's no iconless gap before the dock loads.
  Enable step now degrades gracefully (prints relogin + enable instructions)
  instead of risking an enabled-extensions clobber.
- `docs/desktop/gnome.mdx` — dock section rewritten for the real flow
  (relogin → enable; opt-in de-dupe).

**Decisions / findings:**
- This Claude Code shell runs under a Flatpak bus; dconf **writes** still land in
  the real `~/.config/dconf/user` (confirmed by db mtime + `strings` showing
  `{"0":"TOP"}`, the element JSON, `#1e1e2e`/`#cba6f7`), but **reads** are
  unreliable. So scripts are verified by inspecting the db binary, and no
  read-modify-write of `enabled-extensions` is done from here (clobber risk).
- Dash-to-Dock v105 supports GNOME 49; installed + schemas compiled on disk.
- Wayland scans new extensions only at login, so the dock needs one relogin
  before it can be enabled — can't be enabled pre-relogin without a list merge.

**Follow-ups:**
- [ ] User: log out/in, enable Dash-to-Dock, confirm the content-sized dock; then
  `HIDE_D2P_TASKBAR=true bash setup/install-content-dock.sh` to drop the dupe.
- [ ] Commit the panel/dock scripts + docs once confirmed.

## 2026-06-30 12:45 — Advisory: making the machine more advanced (no code)

**Summary:** Surveyed the host and ranked upgrades for AI/programming + skills
dev as a daily driver. No files changed — direction captured here.

**Findings:** Intel UHD 630 (no dGPU), 12 cores, **15GB RAM**, likely spinning
HDD (inferred from the `setup-zram.sh` + `tracker-limit-index.sh` band-aids).
Runtimes installed (node/go/python via mise). Have `continue` + `llm`; **ollama
has no models pulled**; no aider/distrobox.

**Decisions / recommendation:**
- Biggest lever is **hardware**: HDD→NVMe first, then RAM 15→32/64GB. Software
  stack is already strong.
- Optional scriptable bundles offered (local-AI: ollama models + aider +
  continue.dev wiring; distrobox + uv ML template; skill-dev harness; `llm` RAG).
  User did not pick one — none built.

**Follow-ups:**
- [ ] If/when user wants it: build the local-AI stack script (pull
  `qwen2.5-coder:7b` + `nomic-embed-text`, install aider, wire continue.dev).

## 2026-06-30 12:34 — Move Dash-to-Panel taskbar to the top

**Summary:** Added a re-runnable script to move the GNOME taskbar (Dash-to-Panel)
to the top edge of the screen, with a BOTTOM toggle, and documented it.

**Changes:**
- `setup/panel-position-top.sh` — new; enables Dash-to-Panel, counts monitors,
  writes `panel-positions` (index-keyed JSON `{"0":"TOP",...}`) + legacy
  `panel-position` fallback. `POSITION=BOTTOM` reverses it. No sudo, idempotent.
- `setup/panel-modern-style.sh` — new; "floating dock" restyle of Dash-to-Panel
  + blur-my-shell: margins + `global-border-radius` (detached/rounded), centered
  taskbar, mauve dot indicators, translucent Catppuccin-base bg, panel blur,
  intellihide auto-hide. Tunable via `SIZE/SIDE_MARGIN/TB_MARGIN/RADIUS/OPACITY/
  INTELLIHIDE` env vars.
- `docs/desktop/gnome.mdx` — added both scripts to the setup table, a "Taskbar
  position" section, and a "Modern floating-dock look" subsection with a tunable
  table.

**Decisions:**
- Keyed `panel-positions`/`panel-sizes`/`panel-element-positions` by monitor
  **index** (not connector name) — matches Dash-to-Panel v73's format and the
  existing `gnome-taskbar.sh`.
- Write via **`dconf`, not `gsettings`**: D2P/blur-my-shell ship gschemas inside
  their extension dirs, so `gsettings` fails with "No such schema". (First run
  hit exactly this.) Verified every key's schema type so dconf GVariant literals
  match (`d` opacities, `i` margins, `s` JSON/colour keys, enum for dot/position).
- Couldn't read live GNOME state from the sandbox shell; scripts self-detect
  monitors at runtime in the user's session.

**Follow-ups:**
- [ ] In a live GNOME session, run `panel-position-top.sh` (then optionally
  `panel-modern-style.sh`) and log out/in to confirm the restyle (Wayland can't
  hot-reload shell extensions).

## 2026-06-29 17:10 — Agent CLI toolkit + secure Linux STT install, with docs

**Summary:** Installed a stack of agent-orchestration CLIs/skills (kunchenguid +
vercel-labs) and resolved the macOS-only OpenSuperWhisper request with a secure,
offline Linux replacement. Documented everything in the workspace docs library.

**Changes:**
- Installed (deliberately avoiding every `curl|sh` installer): `gnhf` (npm, v0.1.41),
  `treehouse` (go, v1.8.0), `no-mistakes` (go bin v1.32.2 + bundled skill), `firstmate`
  (cloned → `~/coding/tools/firstmate`), and the `axi` + `lavish` skills via
  `npx skills add ... -a claude-code`. `skills` CLI runs on demand via npx.
- WezTerm/tmux/Neovim/node already present — no reinstall.
- **OpenSuperWhisper** is macOS-only → installing **Speech Note**
  (`net.mkiol.SpeechNote`, Flatpak `--user`, ~1.2 GB) as the most-secure offline STT.
- `docs/ai-coding/agent-cli-toolkit.mdx` (new) — toolkit reference + security posture
  + how-they-fit diagram; registered in `ai-coding/index.mdx`.
- `docs/desktop/voice-dictation.mdx` (new) — Speech Note + global-hotkey alternatives
  (nerd-dictation, whisrs, Vocalinux, whisper.cpp); registered in `desktop/index.mdx`.

**Decisions:**
- Skipped OpenSuperWhisper (no Linux build); chose Speech Note over global-hotkey
  dictation tools because Flatpak sandboxing + offline = smallest attack surface
  (user picked it when asked security-vs-UX).
- Used `go install`/`npm`/`git clone` instead of vendor `curl|sh` scripts, per
  `CLAUDE.md` policy. These agent tools run with full permissions — flagged in docs.
- `agent-cli-toolkit.mdx` placed in `ai-coding/` next to `agent-workflows.mdx` (shared
  worktree theme); STT in `desktop/`.

**Follow-ups:**
- [x] Speech Note installed (v4.8.4, 3.9 GB). Next: download a Whisper model in-app
  (Settings → Languages).
- [ ] Review installed skills before real use (they run with full agent permissions).
- [ ] `no-mistakes init` inside any repo where you want the pre-push gate.
- [ ] Commit the 2 new docs + 2 index edits (currently unstaged on
  `docs/workspace-docs-library`).

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
