# Finishing the Wofi Setup on This Machine

Actionable checklist plus the full reasoning, for the Rocky Linux 10.1 /
GNOME 47 Wayland host. Authored **2026-05-27**.

## TL;DR — the one thing left for you

```bash
# Build + install wofi and gtk-layer-shell (needs sudo — you run it)
bash ~/coding/Dotfiles/chezmoi/private_dot_config/wofi/scripts/install-wofi.sh
```

Everything else is already done (config staged, keybind repointed, chezmoi
fixed, committed + pushed). After the build:

```bash
wofi --show drun        # should appear, Catppuccin-themed
# press Super+Space      # already rebound from rofi to wofi
```

## What was already done for you

| Step | Status | Notes |
|------|--------|-------|
| Config staged to `~/.config/wofi/` | Done | `config` + `style.css` copied; matches the repo (chezmoi shows no diff) |
| `Super+Space` rebound rofi → wofi | Done | Reused slot `custom4`; no duplicate binding |
| chezmoi source root fixed | Done | `.chezmoiroot` added; see below |
| Single source of truth set | Done | chezmoi now reads `~/coding/Dotfiles` |
| Feature committed + pushed | Done | On `SathishKumarAI/Dotfiles` |
| **wofi binary built** | **Pending (sudo)** | The only remaining step — run the script above |

## Machine state (verified, not assumed)

| Thing | State |
|-------|-------|
| `XDG_SESSION_TYPE` | `wayland` (why rofi crashed) |
| `wofi` binary | Not yet installed — build it |
| `gtk-layer-shell` | Not packaged on Rocky 10; built by the same script |
| `~/.config/wofi/` | Staged (`config`, `style.css`) and chezmoi-clean |
| `Super+Space` | Now `wofi --show drun` (was dead `rofi -show drun`) |

## The chezmoi fix (what was wrong, what I changed)

### Problem found
There was no `.chezmoiroot`, so chezmoi treated the **repo root** as its
source and would have scattered files into `$HOME`
(`~/README.md`, `~/chezmoi/.bashrc`, `~/dotfiles/`, `~/assets/`, ...). The real
dotfiles live in the `chezmoi/` subdir with proper `dot_*` names, which is the
intended root. Separately, there were **two diverged clones** of the repo:
`~/coding/Dotfiles` (edited here) and `~/.local/share/chezmoi` (chezmoi's
source, a commit behind).

### What I changed
1. **Added `.chezmoiroot`** (contents: `chezmoi`) at the repo root, so chezmoi's
   source tree is `~/coding/Dotfiles/chezmoi/` only. Repo docs/scaffolding
   (`README.md`, `setup/`, `assets/`, `vault/`, `dotfiles/`, `tools/`,
   `md files/`) are now correctly ignored by chezmoi.
2. **Moved the feature dirs** `remote-desktop`, `rofi`, `wofi` from the old
   root `private_dot_config/` into `chezmoi/private_dot_config/`, so they sit
   under the single source root with the rest of the configs.
3. **Set a single source of truth**: created `~/.config/chezmoi/chezmoi.toml`
   with `sourceDir = "/home/deva/coding/Dotfiles"`. You now edit in one place.
   The old `~/.local/share/chezmoi` clone is orphaned (safe to delete later;
   left in place because the deny list blocks removals).

### Verified after the fix
`chezmoi managed` now maps cleanly: `~/.bashrc`, `~/.config/wofi/...`,
`~/.config/rofi/...`, `~/.config/nvim/...`, etc. — and **no** `~/README.md` or
`~/chezmoi/` junk.

## chezmoi apply: safe for new files, NOT a blanket run

`chezmoi status` shows `apply` would:

- **Add** (safe): all of `~/.config/remote-desktop/...` and the `~/.config/wofi/`
  docs + scripts (these don't exist in `$HOME` yet).
- **Overwrite** (review first): three live configs that have **diverged** from
  the repo —
  - `~/.config/mise/config.toml`
  - `~/.config/starship.toml`
  - `~/.config/zellij/config.kdl`

`~/.bashrc`, `~/.zshrc`, rofi, and the wofi `config`/`style.css` already match
the repo, so apply wouldn't touch them.

**Do not run a blanket `chezmoi apply`** until you decide which version of those
three wins. Safe options:

```bash
# See exactly what would change for the diverged files
chezmoi diff ~/.config/mise/config.toml ~/.config/starship.toml ~/.config/zellij/config.kdl

# If the LIVE versions are canonical, pull them into the repo instead:
chezmoi add ~/.config/mise/config.toml ~/.config/starship.toml ~/.config/zellij/config.kdl

# If the REPO versions are canonical, apply just those:
chezmoi apply ~/.config/mise/config.toml ~/.config/starship.toml ~/.config/zellij/config.kdl
```

wofi needs none of this — it works from the already-staged config.

## Optional cleanup (your call; deny list blocks deletes)

- `~/.local/share/chezmoi/` — orphaned second clone, can be removed
- `~/coding/install-wofi.sh` — superseded by this feature dir
- `~/coding/rofi-wayland-build/` + `setup/setup-rofi-*.sh` — the old X11 rofi
  path; keep as a fallback launcher or retire now that wofi replaces it
- `~/.config/rofi/` — old launcher config (still chezmoi-managed; harmless)
