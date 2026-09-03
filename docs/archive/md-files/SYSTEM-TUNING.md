> **ARCHIVED 2026-08-01 — not the canonical doc.**
> Merged into [`RAM-AND-PERFORMANCE.md`](../../guides/RAM-AND-PERFORMANCE.md); edit that one. Kept here for the
> original wording only. See [archive README](../README.md).

# System Tuning Notes — Arch Linux

Machine: i7-6600U laptop · 16G RAM · NVMe
Snapshot date: 2026-06-05
Boot: 36.8s total (firmware 6.1s + loader 5.6s + kernel 3.4s + **userspace 21.7s**)
Root fs `/` (32G): **81% full** ← main problem · `/home` (202G): 27% (roomy)

---

## 1. Boot faster

### Kill network wait-online stall (biggest win: 5.4s + unblocks chain)
```bash
sudo systemctl disable --now NetworkManager-wait-online.service
```
Safe — only matters for services needing net at boot (none real here).

### Docker — enabled but ZERO images/containers (unused; 1.4s + on net chain)
```bash
sudo systemctl disable --now docker.service docker.socket containerd.service
```
Re-enable anytime: `sudo systemctl enable --now docker.service`. Manual container start still works.

### gnome-remote-desktop — 5.4s, active. Disable IF not RDP-ing into this box
```bash
sudo systemctl disable --now gnome-remote-desktop.service
```

### Leave alone
- TPM units (`systemd-tpm2-setup*`, 4.4s+1.6s) — tied to disk/secure-boot, risky.
- tlp (battery), gdm, NetworkManager — needed.

Expected userspace boot: ~21s → ~10s.

---

## 2. Run faster

### CPU governor stuck `powersave` (scaling 47%). tlp sets it.
On AC want performance:
```bash
sudo nano /etc/tlp.conf
# set:  CPU_SCALING_GOVERNOR_ON_AC=performance
sudo systemctl restart tlp
```
zram already active (4G) + swappiness 60 — good, leave.

---

## 3. Clean space

### Root fs (the real fix) — pacman cache is 5G in /var
```bash
sudo paccache -rk1                 # keep 1 old ver of each pkg
sudo paccache -ruk0                # del all uninstalled pkgs
sudo journalctl --vacuum-size=50M  # trim logs (currently 74M)
```
Frees ~4G off root → ~60%.

### Home cleanup (on /home, roomy, but junk)
```bash
rm -rf ~/.cache/yay/*              # 1.8G AUR build cache
yay -Sc                            # clean yay
```

### Big but DON'T blind-delete
- `~/.config/google-chrome` 5.7G + `~/.cache/google-chrome` 1.5G — your profile/history. Clear inside Chrome.
- `~/Documents/_duplicates` (1.2G) — check, likely leftover.
- `~/Documents/work` 25G, `Obsidian Vault` 12G — your data.

---

## 4. Future tools

| Tool | Use | Status |
|------|-----|--------|
| `paccache` (pacman-contrib) | auto-prune pkg cache | `paccache.timer` enabled ✓ |
| `ncdu` | interactive disk-usage browser | install: `sudo pacman -S ncdu` |
| `systemd-analyze blame` / `critical-chain` | boot profiling | builtin ✓ |
| `tlp` / `tlp-stat` | laptop power tuning | installed ✓ |
| `fstrim.timer` | SSD trim | enabled ✓ |
| `bleachbit` | GUI junk cleaner | install: `sudo pacman -S bleachbit` |

---

## Quick re-diagnose commands (run later)
```bash
systemd-analyze                          # total boot time
systemd-analyze blame | head -20         # slowest units
systemd-analyze critical-chain           # boot dependency chain
df -h /                                   # root fs fullness
du -xhd1 ~ | sort -rh | head             # home hogs
journalctl --disk-usage                   # log size
systemctl --failed                        # broken units
```
