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

## Boot time and disk — the Arch laptop notes

Absorbed from the former `docs/md files/SYSTEM-TUNING.md` (2026-08-01). Snapshot
was the **i7-6600U laptop, 16G, Arch** on 2026-06-05 — boot 36.8s of which
**21.7s was userspace**, and `/` 81% full on a 32G root. Different machine from
the Rocky desktop above, so treat the numbers as that box's, not this one's.

**Boot — three units cost most of the userspace time:**

```bash
sudo systemctl disable --now NetworkManager-wait-online.service  # 5.4s, unblocks the chain
sudo systemctl disable --now docker.service docker.socket containerd.service  # 1.4s, was unused
sudo systemctl disable --now gnome-remote-desktop.service        # 5.4s, only if not RDP-ing in
```

Took userspace ~21s -> ~10s. **Leave alone:** TPM units (tied to disk /
secure boot), `tlp`, `gdm`, NetworkManager itself. Manual `docker start` still
works after disabling the socket; re-enable with `systemctl enable --now`.

**CPU governor** was pinned to `powersave` by tlp, scaling at 47%. On AC:
`CPU_SCALING_GOVERNOR_ON_AC=performance` in `/etc/tlp.conf`, then
`systemctl restart tlp`.

**Root filesystem** — the pacman cache was 5G of the 32G root:

```bash
sudo paccache -rk1                 # keep 1 old version per package
sudo paccache -ruk0                # drop all uninstalled packages
sudo journalctl --vacuum-size=50M
rm -rf ~/.cache/yay/*              # 1.8G of AUR build cache
```

Frees ~4G, root 81% -> ~60%. **Do not blind-delete** browser profile dirs
(`~/.config/google-chrome` was 5.7G) — clear those from inside the browser.

**Re-diagnose later:**

```bash
systemd-analyze                    # total boot
systemd-analyze blame | head -20   # slowest units
systemd-analyze critical-chain     # dependency chain
df -h / ; du -xhd1 ~ | sort -rh | head
journalctl --disk-usage ; systemctl --failed
```

`paccache.timer` and `fstrim.timer` are enabled; `ncdu` and `bleachbit` are the
two worth adding when disk gets tight.

## Related
- `guides/TROUBLESHOOTING.md` — HDD slowness, boot time, other known issues.
- `desktop/disk-usage-and-relocation.md` — docker/containerd disk relocation (different problem: disk, not RAM).
