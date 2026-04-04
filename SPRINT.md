# WinForge — Weekend Sprint 1

**Branch:** `feat/winforge-weekend-sprint-1`
**PR:** https://github.com/SathishKumarAI/Dotfiles/pull/new/feat/winforge-weekend-sprint-1
**Sprint Date:** 2026-04-05 / 06 (Saturday + Sunday)
**Goal:** Bootstrap works clean on 2–3 real machines. Merge to `main`. Tag `v0.9-beta`.

---

## Git History (this sprint — 8 commits)

```
48573f3  docs:  README overhaul + zoxide Windows docs
cb01c0e  feat:  TUI App Manager v4 (60+ apps, AI stack)
093634c  feat:  bootstrap.ps1 one-shot machine setup
21102c9  feat:  env_setup.ps1 + PATH auto-detect script
74a2f18  feat:  Zellij catppuccin theme + dev layout
7190c24  feat:  GlazeWM personal config (workspaces + rules)
4382889  feat:  PowerShell profile + Git Bash .bashrc
2c25d15  chore: .gitignore
```

---

## Saturday — Machine Setup & Testing

| # | Time | Task | Machine | Done When |
|---|---|---|---|---|
| 1 | Morning | Clone branch, run `bootstrap.ps1 -DryRun`, review output | Machine 1 | Dry run prints all 4 steps cleanly |
| 2 | Morning | Run `bootstrap.ps1` fully — note anything that breaks | Machine 1 | Starship + zoxide working in PS |
| 3 | Afternoon | Clone on Machine 2, run full bootstrap | Machine 2 | Same result, no manual fixes |
| 4 | Afternoon | Test `env_setup.ps1` standalone on Machine 2 | Machine 2 | All 6 prompts work; profile updated |
| 5 | Evening | Run `python run.py` TUI App Manager on both | Both | TUI launches; check + install work |

## Sunday — Fix, Merge, Tag

| # | Time | Task | Done When |
|---|---|---|
| 6 | Morning | File GitHub Issues for anything broken on Saturday | Issues filed |
| 7 | Morning | Fix blocking bugs from Saturday testing | `bootstrap.ps1` clean on both machines |
| 8 | Afternoon | Test on 3rd machine (VM or friend's laptop) | 3rd machine checklist passes |
| 9 | Afternoon | Merge branch → `main` via PR | PR merged |
| 10 | Evening | Tag `v0.9-beta` | `git tag v0.9-beta && git push --tags` |

---

## Machine Testing Checklist

> Copy one block per machine. Check off as you go.

### Machine 1 — [ describe: e.g. Home Laptop / Win11 22H2 ]

- [ ] `git clone` works
- [ ] `bootstrap.ps1 -DryRun` runs without error
- [ ] `bootstrap.ps1` completes (all 4 steps)
- [ ] PowerShell: Starship prompt visible
- [ ] PowerShell: `z --help` works
- [ ] PowerShell: `gs` / `gl` git aliases work
- [ ] Git Bash: Starship prompt visible
- [ ] Git Bash: `z --help` works
- [ ] GlazeWM config deployed to `~/.glzr/glazewm/config.yaml`
- [ ] WezTerm launches via `Alt+Enter` in GlazeWM
- [ ] `zellij --layout dev` opens 3-tab session (Code / Shell / Logs)
- [ ] `python run.py` opens TUI App Manager

**Issues found:**
- [ ] _(list here)_

---

### Machine 2 — [ describe: e.g. Work Desktop / Win11 23H2 ]

- [ ] `git clone` works
- [ ] `bootstrap.ps1 -DryRun` runs without error
- [ ] `bootstrap.ps1` completes (all 4 steps)
- [ ] PowerShell: Starship prompt visible
- [ ] PowerShell: `z --help` works
- [ ] PowerShell: `gs` / `gl` git aliases work
- [ ] Git Bash: Starship prompt visible
- [ ] Git Bash: `z --help` works
- [ ] GlazeWM config deployed to `~/.glzr/glazewm/config.yaml`
- [ ] WezTerm launches via `Alt+Enter` in GlazeWM
- [ ] `zellij --layout dev` opens 3-tab session
- [ ] `python run.py` opens TUI App Manager

**Issues found:**
- [ ] _(list here)_

---

### Machine 3 — [ describe: e.g. VM / Friend's Laptop ]

- [ ] `git clone` works
- [ ] `bootstrap.ps1 -DryRun` runs without error
- [ ] `bootstrap.ps1` completes (all 4 steps)
- [ ] PowerShell: Starship prompt visible
- [ ] PowerShell: `z --help` works
- [ ] Git Bash: Starship prompt visible
- [ ] Git Bash: `z --help` works
- [ ] `python run.py` opens TUI App Manager

**Issues found:**
- [ ] _(list here)_

---

## Quick Commands — Run on Each Machine

```powershell
# Step 1 — Clone the sprint branch
git clone -b feat/winforge-weekend-sprint-1 https://github.com/SathishKumarAI/Dotfiles.git
cd Dotfiles

# Step 2 — Dry run first (safe, no changes made)
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -DryRun

# Step 3 — Run for real
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1

# Step 4 — Test the TUI App Manager
pip install -r "win11 installation files\requirements.txt"
python "win11 installation files\run.py"

# Step 5 — Test zellij dev layout
zellij --layout dev

# Step 6 — Health check (after setup)
where starship
where zoxide
where git
where conda
z --help
starship --version
```

---

## Merge Checklist (Sunday afternoon)

- [ ] All Machine 1 checklist items ticked
- [ ] All Machine 2 checklist items ticked
- [ ] Machine 3 core items ticked
- [ ] No P0 bugs open
- [ ] PR reviewed (even solo — read your own diff)
- [ ] PR merged to `main`
- [ ] `git tag v0.9-beta && git push --tags`

---

## Known Risks / Watch Out For

| Risk | What to check |
|---|---|
| Conda not in PATH before `env_setup.ps1` runs | Run PATH fix script first (bootstrap Step 2 before Step 3) |
| GlazeWM config rejects YAML on older versions | Check GlazeWM version: `glazewm --version` (needs v3+) |
| Zellij catppuccin theme not bundled | Zellij ships catppuccin built-in from v0.38+; check version |
| `python run.py` fails — textual version mismatch | Run `pip install -r requirements.txt` to pin correct versions |
| WezTerm path in GlazeWM startup differs per machine | Edit `dotfiles/glazewm/config.yaml` startup_commands if WezTerm installed elsewhere |

---

## Product Roadmap (from Product Plan)

| Phase | Target | Status |
|---|---|---|
| Phase 0 — Foundation Hardening | Distributable bootstrap | ✅ Sprint 1 |
| Phase 1 — MVP v1.0 | `winforge` CLI + doctor + dotfile sync | 🔲 Sprint 2+ |
| Phase 2 — V1.5 Community | Recipe marketplace + `winforge init` wizard | 🔲 Future |
| Phase 3 — V2.0 Cloud/Teams | Cloud sync + team baselines + paid tiers | 🔲 Future |
