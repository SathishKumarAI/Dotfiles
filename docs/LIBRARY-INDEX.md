# Workspace Docs Library — `~/coding/Dotfiles/docs/`

Central, reusable documentation for this machine and all repos. Lives in the Dotfiles
repo (version-controlled) as of 2026-06-18. Start here.

## One topic, one doc

This index is the **single source of truth for where a topic lives**. Every
subject below has exactly one canonical file; nothing is documented twice. When
a topic's home changes, change it here first.

| Topic | Canonical doc |
|---|---|
| Keybindings — every tool | [terminal/KEYBOARD-SHORTCUTS.md](terminal/KEYBOARD-SHORTCUTS.md) (plain text) · [terminal/shortcuts.html](terminal/shortcuts.html) (filterable) |
| Keybindings — hub / conflicts | [keybindings.mdx](keybindings.mdx) · [keybindings-cheatsheet.mdx](keybindings-cheatsheet.mdx) |
| Feature status, this machine | [feature-catalog.mdx](feature-catalog.mdx) |
| Feature catalog, my 18 apps | [features/FEATURES.md](features/FEATURES.md) |
| Windows setup, PATH, CUDA | [setup/windows.mdx](setup/windows.mdx) |
| RAM, boot time, disk tuning | [guides/RAM-AND-PERFORMANCE.md](guides/RAM-AND-PERFORMANCE.md) |
| zoxide | [shell/zoxide.mdx](shell/zoxide.mdx) |

**Retired 2026-08-01.** `docs/md files/` is gone — its four documents were
merged into the canonical files above (`KEYBOARD-SHORTCUTS.md` →
`terminal/`, `zoxide.md` → `shell/zoxide.mdx`, `path_fix.md` →
`setup/windows.mdx`, `SYSTEM-TUNING.md` → `guides/RAM-AND-PERFORMANCE.md`).
The folder's space-in-path names were also the source of every `%20` link in
the tree.

Two files keep similar names on purpose, because they answer different
questions: [`FEATURES.md`](../FEATURES.md) at the repo root is the **per-machine
bring-up checklist** for the Rocky box, while
[`features/FEATURES.md`](features/FEATURES.md) catalogs **the 18 apps I have
built**. Live status of this machine is neither — that is
[`feature-catalog.mdx`](feature-catalog.mdx).

## Guides (this machine)
| Doc | What it covers |
|-----|----------------|
| [guides/MACHINE-CHEATSHEET.md](guides/MACHINE-CHEATSHEET.md) | Daily commands: mise, chezmoi, dnf/flatpak, systemd, GNOME, modern CLI tools. Hardware reality (HDD). |
| [guides/DEV-WORKFLOW.md](guides/DEV-WORKFLOW.md) | New-project bootstrap, git/lazygit/gh, WezTerm/zellij, neovim, Python/conda, documenting work. |
| [guides/CLAUDE-CODE-GUIDE.md](guides/CLAUDE-CODE-GUIDE.md) | Claude Code skills, marketplaces, hooks, templates, MCP (context7) on this machine. |
| [guides/TROUBLESHOOTING.md](guides/TROUBLESHOOTING.md) | Known issues + fixes: HDD slowness, boot time, chezmoi divergence, mise "missing", WezTerm/Wayland, GNOME extensions. |
| [guides/RAM-AND-PERFORMANCE.md](guides/RAM-AND-PERFORMANCE.md) | Stop RAM thrash: triage (RAM vs CPU vs I/O), `ram-monster.py` kill-UI, zram + systemd-oomd + earlyoom prevention stack, idle-stack cleanup, monitor tools (btop/glances/lazydocker). |
| [guides/AGENT-TOOLS-USAGE.md](guides/AGENT-TOOLS-USAGE.md) | How to drive the installed agent tools: skills CLI, AXI, lavish, treehouse, gnhf, no-mistakes, firstmate, Speech Note. |

## Features (catalogs)
| Doc | What it covers |
|-----|----------------|
| [features/FEATURES.md](features/FEATURES.md) | Feature + change catalog of my 18 built apps (bujo, Pickleball-Vision-LLM, Dotfiles, Job/Nexus-Automations, …). |
| [features/UI-UX-FEATURES.md](features/UI-UX-FEATURES.md) | General frontend UI/UX reference (12 sections): layout, forms, feedback, visual design, motion, a11y/perf, components, onboarding, liquid glass, Laws of UX, distinctive design, AI-friendly sites. |

## Setup & platform
| Doc | What it covers |
|-----|----------------|
| [setup/windows.mdx](setup/windows.mdx) | Windows dev + ML setup: script inventory, the four traps (Store Python stub, unwired PowerShell profile, installers that skip PATH, wheel channels), WSL2 driver rule. |
| [setup/ml-devops-pipeline.mdx](setup/ml-devops-pipeline.mdx) | Six-stage orchestrated pipeline (bare box to verified CUDA workstation), state schema, local dashboard, and the five idempotency bugs it exposed. |
| [setup/machine-audit-2026-07-31.md](setup/machine-audit-2026-07-31.md) | Post-provisioning audit: the Virtual Machine Platform blocker (since resolved), duplicate installs, disk, startup, vendor bloat. |
| [setup/windows-validation-2026-08-01.md](setup/windows-validation-2026-08-01.md) | Every Windows feature + app probed live: 33/33 tools, 29/32 apps (3 removed on purpose), dashboard CSRF guards, and the shell-integration gap a PATH-only check could never see. |
| [setup/architecture.mdx](setup/architecture.mdx) | Three-layer provisioning model. |
| [setup/installation-reference.mdx](setup/installation-reference.mdx) | Per-script inventory + timings (Linux snapshot). |

## AI coding
| Doc | What it covers |
|-----|----------------|
| [ai-coding/index.mdx](ai-coding/index.mdx) | Claude Code, skills, hooks, MCP, agent workflows, SDK. |
| [ai-coding/plugins.mdx](ai-coding/plugins.mdx) | Installed plugin set with **measured** always-on token costs, marketplace commands, and the `mlflow` hooks workaround. |
| [PLUGIN-AUDIT.md](PLUGIN-AUDIT.md) | 2026-07-31 plugin audit: 31-row keep/disable decision table, env-key + missing-binary gaps, redundancy map, and the operating guide — per-repo `enabledPlugins` scoping, mid-session toggling, what to measure. 30 enabled → 10. |

## Desktop (system)
| Doc | What it covers |
|-----|----------------|
| [desktop/voice-dictation.mdx](desktop/voice-dictation.mdx) | Offline type-at-cursor voice: nerd-dictation + VOSK + ydotool on GNOME Wayland; Speech Note GUI fallback. Hotkey `Super+\`. |
| [desktop/disk-usage-and-relocation.md](desktop/disk-usage-and-relocation.md) | Disk audit + root→home relocation (docker/containerd/flatpak bind mounts), docker prune vs keep-active, reclaim steps. |

## Fixes (diagnosed issues + resolutions)
| Doc | What it covers |
|-----|----------------|
| [fixes/wezterm-flatpak-env-leak.md](fixes/wezterm-flatpak-env-leak.md) | WezTerm Flatpak leaks `XDG_*`/`DBUS_*`/`ALSA_CONFIG_*` into host shells — silently breaks gsettings, chezmoi, notify-send, and mic capture (Claude Code `/voice`). zshrc un-leak guard. |

## Templates (copy into any repo)
| Path | What it is |
|------|-----------|
| [templates/doc-skeleton.md](templates/doc-skeleton.md) | Anthropic-style doc skeleton. |
| [templates/prompt-skeleton.md](templates/prompt-skeleton.md) | Prompt-engineering skeleton + `prompts/` ready prompts. |
| [templates/README.md](templates/README.md) | House style for docs + prompts. |
| [templates/themes.md](templates/themes.md) | Reusable theme system: light (Square-style) + dark (Catppuccin) on CSS vars, `data-theme` toggle, pill buttons + serif headings. Drop into any project. |
| [templates/ai-friendly-starter/](templates/ai-friendly-starter/) | Frontend starter baking in UI-UX §11 (distinctive) + §12 (AI-friendly): semantic SSR-ready HTML, design tokens w/ glass + a11y fallbacks, `llms.txt`, `robots.txt`. See its README. |

## Worklog
- [WORKLOG.md](WORKLOG.md) — dated session log (also mirrored in `Dotfiles/docs/WORKLOG.md`).

## Location & history
Moved into the **Dotfiles repo** on 2026-06-18 (`~/coding/Dotfiles/docs/`) so it's
version-controlled with everything else. `~/coding/docs` should be a symlink back here
for path compatibility — if it's an empty dir instead, recreate the link:
`rmdir ~/coding/docs && ln -s ~/coding/Dotfiles/docs ~/coding/docs`.

The older standalone worklog from the previous `~/coding/docs/` is preserved as
`WORKLOG-coding-archive.md`; the live worklog is `WORKLOG.md`.

---
*Authoritative machine context: `~/coding/CLAUDE.md`. This library expands on it.*
