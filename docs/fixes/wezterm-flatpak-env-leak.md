# WezTerm Flatpak leaks its sandbox env into host shells

**One-line:** WezTerm is a Flatpak but runs its shell on the *host*, and the
sandbox's `XDG_*`, `DBUS_*`, and `ALSA_CONFIG_*` variables leak into every
terminal — silently breaking `gsettings`, `chezmoi`, `notify-send`, and
microphone capture (including Claude Code `/voice`). Fixed with a guard block in
`~/.zshrc` that resets them to host defaults.

Diagnosed 2026-07-14 on Rocky Linux 10 / GNOME 49 Wayland, WezTerm from Flathub
(`org.wezfurlong.wezterm`).

---

## Symptom that started it

"Microphone not working in Claude Code voice mode — but it works in Chrome."

It was never the mic. The Logitech C270 recorded clean audio from a plain CLI the
whole time. Chrome works because GNOME launches it with a clean environment;
WezTerm does not.

## Root cause

WezTerm ships as a Flatpak, but the terminal it opens is a **host** shell — there
is no `/.flatpak-info`, `/home` is real, host binaries run. Yet the shell still
**inherits the sandbox's environment**. Every environment-respecting tool then
reads and writes the wrong place, with **no error** — just wrong answers:

| Leaked var | Points at (sandbox-only) | What breaks |
|-----------|--------------------------|-------------|
| `XDG_CONFIG_HOME` | `~/.var/app/org.wezfurlong.wezterm/config` | tools read a phantom config dir |
| `XDG_DATA_HOME` | `~/.var/app/org.wezfurlong.wezterm/data` | `chezmoi source-path` resolves to a nonexistent dir |
| `XDG_CACHE_HOME` / `XDG_STATE_HOME` | `…/cache`, `…/.local/state` | cache/state written under the app dir |
| `DBUS_SESSION_BUS_ADDRESS` | `unix:path=/run/flatpak/bus` | `gsettings` writes, `dconf`, `notify-send` all fail against a socket that only exists inside the sandbox |
| `ALSA_CONFIG_PATH` | `/usr/share/alsa/alsa-flatpak.conf` | **no such file on host → ALSA loads no config → "Unknown PCM default" → all mic capture dies** |

The audio one is the headline. Claude Code's `/voice` (hold-to-talk dictation)
shells out to `arecord` (probed first) or `sox`. With the leaked
`ALSA_CONFIG_PATH`, `arecord` can't open the default device:

```
Cannot access file /usr/share/alsa/alsa-flatpak.conf
ALSA lib pcm.c: Unknown PCM default
arecord: main:850: audio open error: No such file or directory
```

so `/voice` reports no microphone.

## Confirming it

```sh
# See the leak
env | grep -E '^XDG_|^DBUS_|^ALSA_|^FLATPAK_'

# Capture fails with the leaked ALSA vars set:
arecord -f cd -d 2 /tmp/t.wav          # -> Unknown PCM default

# Capture works the instant they're gone:
env -u ALSA_CONFIG_PATH -u ALSA_CONFIG_DIR arecord -f cd -d 2 /tmp/t.wav   # -> records fine
```

## The fix

A guard block in `~/.zshrc` (mirrored in the repo copy
`dotfiles/chezmoi/dot_zshrc`). It fires only when `FLATPAK_ID` is set **and**
`/.flatpak-info` is absent — i.e. exactly the "Flatpak-launched shell running on
the host" case — and resets everything to host defaults:

```sh
# Un-leak the Flatpak environment. WezTerm is a Flatpak but spawns its shell on
# the HOST (no /.flatpak-info here), yet the sandbox's XDG_* and DBUS vars are
# still inherited. Left alone, every XDG-respecting tool in this terminal reads
# and writes ~/.var/app/org.wezfurlong.wezterm/* instead of the real dirs.
if [[ -n "$FLATPAK_ID" && ! -f /.flatpak-info ]]; then
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CONFIG_DIRS="/etc/xdg"
    export XDG_DATA_DIRS="/usr/local/share:/usr/share:/var/lib/flatpak/exports/share:$XDG_DATA_HOME/flatpak/exports/share"
    export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus"
    # ALSA_CONFIG_PATH points at /usr/share/alsa/alsa-flatpak.conf, which exists
    # ONLY inside the sandbox. On the host ALSA then loads no config at all, so
    # the "default" PCM never resolves and every capture dies with
    # "Unknown PCM default". That breaks arecord — which is what Claude Code's
    # /voice mode shells out to.
    unset ALSA_CONFIG_PATH ALSA_CONFIG_DIR
    unset FLATPAK_ID FLATPAK_SANDBOX_DIR
fi
```

Open a **new** tab after editing (existing shells keep the stale env), then
verify:

```sh
echo "$XDG_CONFIG_HOME"          # -> /home/<you>/.config
chezmoi source-path              # -> /home/<you>/.local/share/chezmoi
arecord -f cd -d 2 /tmp/t.wav    # -> records
```

## Using Claude Code voice after the fix

`/voice` is already enabled in `~/.claude/settings.json`
(`"voice": {"enabled": true, "mode": "hold"}`). In a fresh WezTerm tab: run
`claude`, type `/voice`, hold to talk, release to transcribe into the prompt.
`arecord` (from `alsa-utils`) is enough; `sox` is optional — Claude prefers it
when present (`sudo dnf install sox`).

## Gotchas learned here

- **`~/.zshrc` is NOT chezmoi-managed.** The repo's `chezmoi/dot_zshrc` is a
  hand-kept copy that had already drifted from the live file. Edit **both**.
- The `claude` binary itself lives under the leaked data dir
  (`~/.var/app/org.wezfurlong.wezterm/data/claude/versions/<v>`) via an absolute
  symlink at `~/.local/bin/claude`, so resetting `XDG_DATA_HOME` does **not**
  break launching. Still a fragile install location worth relocating out of the
  Flatpak tree eventually.
- Any Flatpak terminal (not just WezTerm) that runs host shells hits this same
  class of bug. The guard keys off `FLATPAK_ID` generically.

## Related

- [../desktop/voice-dictation.mdx](../desktop/voice-dictation.mdx) — the other
  voice path: offline type-at-cursor via nerd-dictation + VOSK + ydotool.
- [../guides/TROUBLESHOOTING.md](../guides/TROUBLESHOOTING.md) — other known
  machine issues (chezmoi divergence, HDD slowness).
