# Machine Audit - 2026-07-31

Windows 11 Home 26200 | Ryzen 7 9800X3D | 31.2 GB | RTX 5070 Ti 16 GB | 1x 1920x1080

Snapshot taken after the Windows -> ML/DevOps provisioning run. 65 programs in
Add/Remove Programs: 30 installed by the pipeline, 35 pre-existing.

> **Resolved 2026-08-01.** `vmcompute.exe` is present and `wsl --status` reports
> Default Version 2. What is left is not a blocker: no distro is installed, and
> Docker Desktop is simply not running. See
> [Windows Validation](./windows-validation-2026-08-01.md).

## Blocker: Virtual Machine Platform is not enabled

This one setting breaks **both** Docker and WSL2.

```
Edition                       Windows 11 Home     <- not the problem
Firmware virtualization (SVM) True                <- BIOS already correct
vmcompute.exe                 MISSING             <- the actual cause
docker version                500 Internal Server Error (Linux engine)
com.docker.service            Stopped
```

**Docker Desktop does not need Windows Pro.** Pro is only required for the
Hyper-V backend and Windows containers. On Home, Docker runs the **WSL2
backend**, which uses *Virtual Machine Platform* - a Hyper-V subset that Home
does ship. Docker Desktop was running (8 processes); its Linux engine simply
had no VM to start on.

Fix, once, from an elevated shell, then reboot:

```powershell
wsl --install --no-distribution
```

Note `wsl --status` reports this as "virtualization is not enabled on this
machine", which reads like a BIOS problem and is not. See
[Windows Setup](./windows.mdx) for how to tell the two causes apart.

## Duplicate installs

Four CLI tools exist twice - a winget copy and a scoop copy. scoop wins on
PATH; the winget copies are dead weight and will drift in version.

| Tool | Active | Redundant |
|---|---|---|
| `rg` `fd` `fzf` `zoxide` | `~/scoop/shims` | `AppData/Local/Microsoft/WinGet/Packages/...` |

```powershell
winget uninstall BurntSushi.ripgrep.MSVC sharkdp.fd junegunn.fzf ajeetdsouza.zoxide
```

`python` also resolves twice: the real 3.12.10 wins, with the dead Microsoft
Store stub still behind it on PATH. Turn the alias off in Settings > Apps >
Advanced app settings > App execution aliases.

## Disk

| Item | Size | | Item | Size |
|---|---|---|---|---|
| `~/.venvs/ml` | **5.53 GB** | | Docker Desktop | 3.4 GB |
| Microsoft Edge | 2.0 GB | | LM Studio | 2.0 GB |
| PowerToys | 1.2 GB | | Obsidian | 1.1 GB |
| PostgreSQL 17 | 1.0 GB | | VS Code | 1.0 GB |
| LibreOffice | 772 MB | | `~/scoop` | 720 MB |

## Startup - 5 entries, lean

| Entry | Verdict |
|---|---|
| SecurityHealth | keep - Defender tray |
| OneDrive | keep if you use it |
| Docker Desktop | heavy (3.4 GB) and currently non-functional |
| MicrosoftEdgeAutoLaunch | **bloat** - Edge preloading itself |
| ZEUS Switch Utility | GAMDIAS peripheral software |

## Vendor stack worth questioning on a dev box

Armoury Crate Service, AURA lighting add-on (x2), AURA Service, ASUS Framework
Service, GameSDK Service, ROG Live Service, ZEUS CAST. RGB lighting and gaming
overlays running background services. NVIDIA Overlay alone holds ~347 MB.

## Installed by the pipeline you may not want

| Item | Note |
|---|---|
| ExplorerPatcher | **removed** - made Windows 11 render as Windows 10 |
| GlazeWM + Zebar | **stopped, kept installed** - low value on a single 1080p screen; worth re-enabling with a second monitor |
| Brave, Zen | you now have 4 browsers; these two are 911 MB |
| LibreOffice | 772 MB |
| MiKTeX | only needed for Pandoc -> PDF |
| PostgreSQL 17 | 1 GB, only if you run Postgres locally |

## Memory at snapshot

15.9 / 31.2 GB in use. Chrome 4.7 GB across 26 processes, Claude 2.6 GB,
VS Code 2.2 GB.
