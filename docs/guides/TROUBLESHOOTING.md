# Troubleshooting — Known Issues on This Machine

Real, observed issues with fixes. Dated where diagnosed.

## Machine feels slow / laggy (2026-06-18)
**Cause:** Everything (`/` + `/home`) is on one **7200rpm spinning HDD** (no SSD).
12 cores + 11G free RAM sit idle — the box is **I/O-bound**.
**Not the cause:** disk space (14% full, 741G free) — cleaning won't help speed.
**Fixes (scripts in `Dotfiles/setup/`):**
- `bash setup/optimize-responsiveness.sh` (no sudo) → tames tracker3 indexer thrashing
  the 37G `~/Documents`, disables heavy extensions (blur-my-shell, Vitals) + tiling
  stack. **Log out/in after.** Reversible.
- `sudo bash setup/speedup-boot.sh` → docker socket-activation, plocate timer off (~46s).
**Real fix:** add an SSD, move `/` + `/home` onto it.

## Boot takes ~4m40s userspace
`graphical.target` is reached at ~47s; the long tail is background jobs + HDD device
detection. Offenders: plymouth-quit-wait 30s (harmless splash wait), docker 17s,
plocate-updatedb 16s, containerd 13s. `speedup-boot.sh` trims docker/containerd/plocate.
Check with `systemd-analyze blame` and `systemd-analyze critical-chain`.

## chezmoi source diverged
**Symptom:** `chezmoi managed` returns empty; `apply` behaves oddly.
**Cause:** live `~/.local/share/chezmoi` source is broken / out of sync with the repo,
plus a `.config` conflict.
**Workaround:** Canonical source = `~/coding/Dotfiles/chezmoi/`. Edit BOTH the repo
file AND the live rc file until repaired. Re-import shell rc into the live source.

## mise runtimes show "(missing)"
**Symptom:** `mise ls` lists python/node/go as `(missing)`.
**Cause:** the ACTIVE interpreters aren't mise-managed — `python` is miniforge
(`~/miniforge3/bin`), `node` is system (`/usr/bin/node`). mise config declares them
but they're not installed under mise.
**Options:** (a) `mise install` to let mise own them, then ensure mise shims come first
in PATH; or (b) leave as-is and be explicit per project (conda env for Python, system
node for JS). Don't assume `mise exec` and a bare `python` are the same interpreter.

## WezTerm won't launch on Wayland (historical)
`XOpenDisplay failed` — fixed in config. If a Mutter explicit-sync crash returns
(`Protocol error os error 71`), switch `front_end` to `"OpenGL"` or upgrade wezterm.
Benign `xkbcommon dead_hamza` Compose warnings on startup — system locale data, ignore.

## After GNOME extension changes, nothing updates
Wayland can't hot-reload extension state cleanly — **log out and back in** for a clean
result. Applies to PaperWM, AATWS, Dash to Panel, tracker masking.

## PaperWM fights Tiling Assistant
If scrolling tiling behaves oddly:
`gnome-extensions disable tiling-assistant@leleat-on-github`.
