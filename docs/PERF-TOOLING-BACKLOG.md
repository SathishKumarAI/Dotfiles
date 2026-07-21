# Performance Tooling — Backlog & Status

> RAM/OOM/perf tools built to stop the machine thrashing. `🟢 working · 🟡 needs sudo run · 🔴 todo`.
> Checklist block feeds the local **Khanban** board. All tools run **fully local** — stdlib/CLI, no cloud, no Claude.
> Built 2026-07-11 → 2026-07-12. Guide: `docs/guides/RAM-AND-PERFORMANCE.md`.

## What works now
| Tool | State | Notes |
|---|---|---|
| `scripts/ram-monster.py` | 🟢 | Find/kill RAM+swap hogs. `--serve` = local web UI (127.0.0.1:8765) with kill/stop buttons. Pure stdlib. |
| `scripts/drain-swap.sh` | 🟡 | Reclaim swap to RAM (checks free RAM first). Needs sudo — run via `! bash …`. |
| `scripts/install-system-tools.sh` | 🟡 | Installs prevention stack (zram + systemd-oomd + earlyoom + swappiness). Idempotent, needs sudo. |
| glances 4.5.5 + web (`glances -w`) | 🟢 | Installed via pip. |
| btop · htop · lazydocker · ctop | 🟢 | Already present. |
| `docs/guides/RAM-AND-PERFORMANCE.md` + index | 🟢 | Triage, how-to, OSS table. |

<!-- khanban:start -->
### Done
- [x] ram-monster.py: local web UI + CLI to find and kill RAM/swap hogs (done 2026-07-11)
- [x] drain-swap.sh: safe swap reclaim with free-RAM guard (done 2026-07-11)
- [x] install-system-tools.sh: zram + systemd-oomd + earlyoom + swappiness (done 2026-07-11)
- [x] Install glances + web deps, confirm btop/htop/lazydocker/ctop present (done 2026-07-11)
- [x] RAM-AND-PERFORMANCE.md guide + LIBRARY-INDEX entry (done 2026-07-11)
- [x] Copy tools into dotfiles/scripts for version control (done 2026-07-12)
- [x] Live rescue: stopped 19 idle containers + killed idle next-server, load 9.9 to ~4 (done 2026-07-11)

### Backlog (future)
- [ ] Run install-system-tools.sh (sudo) to make prevention permanent across reboots
- [ ] Run drain-swap.sh to reclaim the ~2.6 GB still in swap
- [ ] Commit the 3 scripts + guide to the dotfiles repo
- [x] Fix ~/.bashrc syntax error (line 53 'fi') that prints on every command (done 2026-07-13)
- [x] speedup-all.sh: one-shot orchestrator running every speedup in order (done 2026-07-13)
- [ ] Optional: systemd user timer to auto-run ram-monster report daily
- [ ] Optional: track ram-monster.py via chezmoi so it deploys to ~/.local/bin
- [ ] Optional: add netdata for historical/alerting web dashboard
<!-- khanban:end -->
