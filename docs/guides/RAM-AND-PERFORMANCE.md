# RAM & Performance — stop the machine thrashing

> **The point:** this box (16 GB RAM) gets slow not from CPU or disk-full, but from
> **leftover dev servers + Docker stacks eating RAM until pages spill to disk-swap and thrash.**
> Fix = stop idle stacks, use compressed RAM-swap (zram), and let an OOM-killer cull the worst
> hog *before* the freeze. Tools below make it one command.

## Is it actually RAM? (30-second triage)
| Command | What it tells you |
|---|---|
| `uptime` | Load high? Note: load counts **I/O-blocked** procs too, not just CPU. |
| `free -h` | `Swap used` high (>2–3 GB) = you're thrashing. `available` low = RAM pressure. |
| `vmstat 1 3` | `wa` high + `si` (swap-in) spiking = disk-swap thrash. `r` low + `b` high = blocked on I/O, **not** CPU-bound. |
| `python3 ~/coding/scripts/ram-monster.py` | Ranked RAM/swap hogs + idle dev servers + Docker containers, one screen. |

**Rule of thumb:** CPU idle but load high + swap filling → it's memory, not compute.

## The three scripts (in `~/coding/scripts/` and `dotfiles/scripts/`)
| Script | Does | Sudo? |
|---|---|---|
| `ram-monster.py` | Find & kill hogs. `--serve` gives a **local web UI** (127.0.0.1:8765) with kill/stop buttons. Pure stdlib. | no |
| `install-system-tools.sh` | Installs the **prevention** stack: zram + systemd-oomd + earlyoom + low swappiness. Idempotent. | yes |
| `drain-swap.sh` | Force-drains pages stuck in swap back to RAM (checks free RAM first). Run after freeing memory. | yes |

### How to use
```bash
# see what's eating RAM (terminal)
python3 ~/coding/scripts/ram-monster.py

# web UI with kill/stop buttons — local only, nothing leaves the machine
python3 ~/coding/scripts/ram-monster.py --serve      # → http://127.0.0.1:8765

# one-time: install prevention stack (run once, survives reboots)
bash ~/coding/scripts/install-system-tools.sh

# after stopping stacks, reclaim swap
bash ~/coding/scripts/drain-swap.sh
```

## Prevention stack (what `install-system-tools.sh` sets up)
| Piece | Why it matters here |
|---|---|
| **zram** (compressed RAM swap, zstd) | Your swap was a **disk partition** — slow, the thrash source. zram swaps into compressed RAM instead: ~3× faster, higher priority than disk swap. Biggest single win. |
| **systemd-oomd** | Native. Kills the worst cgroup when swap >85% or memory pressure >60% for 20 s — *before* the whole desktop freezes. |
| **earlyoom** | Installed but disabled (avoids double-kill with oomd). Simpler alternative if you prefer it. |
| **vm.swappiness=10** | Kernel prefers keeping pages in RAM over swapping early. |

## Killing idle stuff by hand
```bash
docker ps                      # see running stacks
docker stop <name…>            # stop a stack you're not using (reversible: docker start)
lazydocker                     # TUI: browse containers + their RAM, stop/kill
pkill -f 'next-server'         # kill stray Next.js dev servers (check `readlink /proc/PID/cwd` first)
```
**Habit:** `docker compose down` when you finish with a project. A Supabase stack alone is ~11
containers; three of those left running = your RAM is gone.

## Open-source tools (installed on this machine)
| Tool | Use | Install |
|---|---|---|
| **btop** | Best TUI monitor; kill with a keypress | `dnf` (present) |
| **htop** | Classic process monitor | `dnf` (present) |
| **glances** | Monitor with a **built-in web dashboard**: `glances -w` → browser | `pip install glances[web]` (present) |
| **lazydocker** | TUI to stop/kill containers + see their RAM | `~/.local/bin` (present) |
| **ctop** | `top` for containers | `~/.local/bin` (present) |
| **netdata** | Full real-time web monitoring + alerts (heavier) | not installed — `dnf install netdata` if wanted |

**Recommended combo for this box:** zram + systemd-oomd (auto-prevent) · lazydocker (stacks are
the main hogs) · `ram-monster.py --serve` (tailored kill UI) · `btop` / `glances -w` (watch).

## Related
- `guides/TROUBLESHOOTING.md` — HDD slowness, boot time, other known issues.
- `desktop/disk-usage-and-relocation.md` — docker/containerd disk relocation (different problem: disk, not RAM).
