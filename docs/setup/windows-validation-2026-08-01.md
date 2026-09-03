# Windows Validation - 2026-08-01

Windows 11 Home 26200 | Ryzen 7 9800X3D | 31.2 GB | RTX 5070 Ti 16 GB

Every feature and application this repo claims to provision on Windows, probed
against the live machine one day after the [provisioning run](./machine-audit-2026-07-31.md).
Result: **the pipeline itself is sound** - one silent failure class, two apps
installed but unreachable, three apps deliberately removed.

## Verdict

| Area | Result |
|---|---|
| Pipeline stages | 5 ok, `wsl` pending (opt-in, never run) |
| CLI tool inventory | **33 / 33** present (was 30/30 before the probe list grew) |
| scoop cluster | 13 / 13 |
| winget packages | 29 / 32 intended - 3 removed on purpose |
| GPU -> PyTorch gate | cu128 on sm_120, `matmul` verified **on device** |
| Dashboard | serves, all routes 200, all 3 CSRF guards hold |
| Docs link check | was 15 broken, now **0** |
| Shell integration | **was completely absent** - fixed, see below |

## The real finding: installed is not wired

`zoxide`, `starship` and `mise` were all installed, all on `PATH`, all
resolvable by every probe in this repo - and all inert. `z` did not exist.

**No PowerShell profile existed at all.** All four candidate paths were empty:

```
Documents\PowerShell\Microsoft.PowerShell_profile.ps1        missing
Documents\PowerShell\profile.ps1                             missing
Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 missing
Documents\WindowsPowerShell\profile.ps1                      missing
```

The Linux side has always done this - `install-workflow-tools.sh` appends
`eval "$(zoxide init bash)"` to `.bashrc`. The Windows side installed the same
binaries and wired none of them, and nothing caught it because **every check in
the repo tested `PATH`, and `PATH` was correct.**

Fix, now shipped:

| Change | File |
|---|---|
| Profile with zoxide/starship/mise init, PSReadLine, eza+bat aliases, `ws`/`dot`/`ml` shortcuts | `assets/powershell-profile.ps1` |
| Copies it to `$PROFILE` when none exists, never overwrites | `setup/setup-windows.ps1` |
| **Shell integration** panel - probes the profile, not the binary | `tools/mlops_dashboard.py` |

Verified after the fix, in a fresh shell:

```
z docs   -> C:\...\dotfiles\docs
z setup  -> C:\...\dotfiles\setup
```

Three follow-ons the fix itself produced, all caught by re-running the probes:

1. **`$PROFILE` is per-host.** These scripts are documented as `powershell -File`,
   which is Windows PowerShell 5.1 — so `$PROFILE` resolved to
   `Documents\WindowsPowerShell` and would have left **PowerShell 7, the shell
   actually in use, with no profile.** Both hosts are now targeted explicitly.
2. **PSReadLine aborts redirected runs.** `-PredictionSource History` throws
   when stdout is redirected, killing the rest of the profile. Gated on
   `SupportsVirtualTerminal` and `[Console]::IsOutputRedirected`.
3. **The shell answered for the tool.** The inventory dropped 33 -> 32: `mise`
   read as missing while `mise --version` worked. `mise activate` defines a
   PowerShell *function* named `mise`; `Get-Command` returns it ahead of the
   executable, and a function has no `.Source`, which the probe required. Both
   PowerShell probes now ask for `-CommandType Application` first. The Python
   dashboard was never affected — `shutil.which` cannot see a shell function.

## Installed but unreachable

Both were reported successful by `winget` and both were unusable, because
neither installer touches `PATH` and the repo never looked for them.

| Tool | Actually at | Fix |
|---|---|---|
| `tesseract` | `C:\Program Files\Tesseract-OCR` | added to `update-user-path.ps1` detection |
| `wget` | ships as **`wget2.exe`** - there is no `wget` | probe renamed to `wget2` |

`pandoc` resolved on its own. All three now appear in the pipeline inventory
under a new **Docs & OCR** category, which is why the count moved 30 -> 33.

## Deliberately absent

Three packages the scripts install are gone by choice - the removals recorded
in the [machine audit](./machine-audit-2026-07-31.md), not regressions:

| Package | Why |
|---|---|
| `valinet.ExplorerPatcher` | rendered Windows 11 as Windows 10 |
| `glzr-io.zebar` | GlazeWM status bar, low value on one 1080p screen |
| `Brave.Brave` | fourth browser, 911 MB with Zen |

Skip them on a rebuild with `-Groups Dev,Docs,AI`.

## The 2026-07-31 blocker is cleared

The audit's headline blocker - Virtual Machine Platform missing, breaking both
Docker and WSL2 - is resolved:

```
vmcompute.exe                 present     (was MISSING)
Firmware virtualization (SVM) True
wsl --status                  Default Version: 2
```

What remains is not a blocker:

- **No WSL distro installed.** `wsl -l -v` reports none. The `wsl` stage is
  opt-in (`-IncludeWsl`) and has never been run.
- **Docker engine down** - `com.docker.service` stopped, Docker Desktop not
  running, so `docker version` fails on the Linux engine pipe. Start Docker
  Desktop; the missing-VM cause is gone.

## Dashboard

Probed live, server bound to `127.0.0.1:8765`:

| Check | Result |
|---|---|
| `GET /` | 200, 48.7 KB, no unreplaced template tokens |
| `GET /api/state`, `/api/runs` | 200 |
| `POST /api/run` no token | 403 |
| `POST /api/run` wrong token | 403 |
| `POST /api/run` foreign `Origin` | 403 |
| read-only default | run refused without `--allow-run` |

One robustness note: the state file is written by PowerShell with a UTF-8 BOM.
`load_state()` already reads it as `utf-8-sig`; a plain `json.load` on that file
fails with `Expecting value: line 1 column 1`. Worth remembering for any new
consumer of `setup/state/pipeline-state.json`.

## Docs

`tools/check_docs.py` reported 15 broken internal links across 9 files, all
from the docs-library move: `md files/` went under `docs/`, but the links kept
their old `../` depth, and four pointed at `~/coding/CLAUDE.md`, which lives
outside this repo and cannot be linked relatively. Depths corrected, the
CLAUDE.md links unlinked to plain code spans. Now: `58 .mdx files, 260 internal
links, all good`.

## Not validated here

Every Linux-only feature in [FEATURES.md](../../FEATURES.md) - wofi, rofi,
GNOME, cliphist, RustDesk, the `~/.local/bin` launcher scripts. Those target
the Rocky box; that checklist is not applicable to this machine.

## See also

- [Windows Setup](./windows.mdx) - installers and traps
- [Windows to ML/DevOps Pipeline](./ml-devops-pipeline.mdx) - stages and dashboard
- [Machine Audit 2026-07-31](./machine-audit-2026-07-31.md) - the snapshot this validates
