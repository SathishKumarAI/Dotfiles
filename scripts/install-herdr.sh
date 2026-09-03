#!/usr/bin/env bash
# install-herdr.sh
# Install Herdr — "the runtime your coding agents live on" — plus its Claude Code
# integration and the official herdr skill.
#
#   bash ~/coding/workspace/dotfiles/scripts/install-herdr.sh
#
# Idempotent: re-running is safe. Steps report and continue on failure so one
# missing optional piece never aborts the rest.
#
# WHAT THIS ADDS, AND WHAT IT DOES NOT TOUCH
#   Herdr is the multiplexer for AGENT work: it detects Claude Code in a pane,
#   tracks semantic state (idle/working/blocked/done), rolls that up a sidebar so
#   you can see which of several parallel agents needs a decision, and keeps
#   panes alive across detach.
#   zellij (general multiplexing), tmux (remote fallback) and resurrect.wezterm
#   (WezTerm window-layout persistence) are ALL left intact. Herdr is added, it
#   replaces nothing — see docs/terminal/index.mdx for which tool is for what.
#
# VERSION IS PINNED ON PURPOSE
#   Herdr is pre-1.0 (v0.7.5, released 2026-07-21; repo created 2026-03-27) and
#   versions its client/server protocol. Pinning means an upstream break is a
#   deliberate bump, not a surprise on a random Tuesday.
#
# This script does NOT start a server and does NOT modify ~/.claude/settings.json.

set -uo pipefail

HERDR_VERSION="0.7.5"
SKILLS_DIR="${SKILLS_DIR:-$HOME/coding/workspace/claude-skills}"
SKILL_URL="https://raw.githubusercontent.com/herdrdev/herdr/master/skills/herdr/SKILL.md"

run() {
  echo "+ $*"
  "$@" || echo "  (continuing — likely already done)"
}

have() { command -v "$1" >/dev/null 2>&1; }

echo "== 1/4  herdr binary (pinned v${HERDR_VERSION}) =="

if have herdr; then
  echo "already installed: $(herdr --version 2>/dev/null || echo 'version unknown')"
  echo "  (to move to the pinned version: mise use -g herdr@${HERDR_VERSION})"

# mise is this machine's runtime manager (see CLAUDE.md), so it is the preferred
# path: pinned, rollbackable, one place to see every managed tool. Upstream
# advertises `mise use -g herdr`, but the registry entry could not be confirmed
# ahead of time — so probe for it rather than assume, and fall back cleanly.
elif have mise && mise registry 2>/dev/null | grep -qE '^herdr[[:space:]]'; then
  run mise use -g "herdr@${HERDR_VERSION}"
  have mise && run mise reshim

else
  # Fallback: pinned release binary. Deliberately NOT the upstream
  # `curl -fsSL https://herdr.dev/install.sh | sh` one-liner — this repo already
  # declined that pattern once for caveman (see install-claude-skills.sh); piping
  # unreviewed remote code into a shell as your own user is the thing being avoided.
  if have mise; then
    echo "mise present but no 'herdr' registry entry found — using pinned release binary."
  else
    echo "mise not found — using pinned release binary."
  fi

  arch="$(uname -m)"
  case "$arch" in
    x86_64)        asset="herdr-linux-x86_64" ;;
    aarch64|arm64) asset="herdr-linux-aarch64" ;;
    *) echo "  unsupported arch '$arch' — install manually from"
       echo "  https://github.com/herdrdev/herdr/releases/tag/v${HERDR_VERSION}"
       asset="" ;;
  esac

  if [ -n "$asset" ]; then
    url="https://github.com/herdrdev/herdr/releases/download/v${HERDR_VERSION}/${asset}"
    tmp="$(mktemp)"
    echo "+ curl -fL $url"
    if curl -fL --proto '=https' --tlsv1.2 -o "$tmp" "$url"; then
      # Upstream publishes no checksum file alongside the release assets, so
      # there is nothing to verify against automatically. Print the hash instead
      # of pretending it was checked — compare it against the release page if
      # you care, and it gives you a record of exactly what landed.
      if have sha256sum; then
        echo "  sha256: $(sha256sum "$tmp" | cut -d' ' -f1)"
        echo "  (no upstream checksum file to verify against — compare manually if desired)"
      fi
      mkdir -p "$HOME/.local/bin"
      chmod +x "$tmp"
      mv "$tmp" "$HOME/.local/bin/herdr"
      echo "  installed → ~/.local/bin/herdr"
    else
      echo "  download failed — install manually from"
      echo "  https://github.com/herdrdev/herdr/releases/tag/v${HERDR_VERSION}"
      rm -f "$tmp"
    fi
  fi
fi

echo
echo "== 2/4  Claude Code integration =="
# Without this, herdr classifies Claude Code by scraping the pane's bottom
# buffer against a TOML manifest. The integration adds hook/plugin reports, so
# 'working' vs 'blocked' vs 'done' stops being purely visual guesswork.
# Upstream is explicit that Claude Code still does not hand herdr full lifecycle
# authority, so treat 'done' as a strong hint rather than gospel.
if have herdr; then
  run herdr integration install claude
  run herdr integration status
else
  echo "herdr not on PATH yet — open a new shell (or run 'mise reshim'), then:"
  echo "  herdr integration install claude"
fi

echo
echo "== 3/4  official herdr skill for Claude Code =="
# Lets Claude Code drive herdr itself: split panes, run commands, read pane
# output, start and prompt other agents. Vendored under claude-skills/vendor/
# because it is upstream's file, not ours — claude-skills/mine/ is for our own
# (see CLAUDE.md). Symlinked into ~/.claude/skills/ the same way as the rest.
skill_dest="$SKILLS_DIR/vendor/herdr"
if mkdir -p "$skill_dest" 2>/dev/null; then
  echo "+ curl -fsSL $SKILL_URL"
  if curl -fsSL "$SKILL_URL" -o "$skill_dest/SKILL.md"; then
    mkdir -p "$HOME/.claude/skills"
    ln -sfn "$skill_dest" "$HOME/.claude/skills/herdr"
    echo "  installed → $skill_dest  (symlinked to ~/.claude/skills/herdr)"

    # Keep the machine-wide skill index honest (CLAUDE.md: one index for every
    # skill on this machine).
    index="$SKILLS_DIR/README.md"
    if [ -f "$index" ] && ! grep -q "vendor/herdr" "$index"; then
      printf '\n- `vendor/herdr` — control Herdr panes/tabs/agents from Claude Code (upstream, Apache-2.0)\n' >> "$index"
      echo "  added a row to $index"
    fi
  else
    echo "  fetch failed — skill not installed (herdr itself still works)"
  fi
else
  echo "  $SKILLS_DIR not writable — skipping skill install"
fi

echo
echo "== 4/4  config =="
echo "Config is chezmoi-managed. Apply it with:"
echo "  chezmoi apply ~/.config/herdr/config.toml"
echo
echo "NOTE: herdr's own default shell is nushell. The tracked config overrides it"
echo "      to /bin/zsh — without that, none of your zsh setup (aliases, plugins,"
echo "      the Flatpak env guard) exists inside agent panes."

echo
echo "== verify =="
cat <<'VERIFY'
  herdr --version                # expect 0.7.5
  herdr status                   # server + client state

  # From a WEZTERM pane specifically — WezTerm is a Flatpak and a leaked
  # XDG_CONFIG_HOME would hide the socket under the sandbox path:
  echo "$XDG_CONFIG_HOME"        # MUST be /home/<you>/.config, not ~/.var/app/...

  cd <a project> && herdr        # then start `claude` in a pane
  herdr agent list               # claude should appear
  herdr agent explain <target> --json   # shows WHY it classified that way

  ctrl+g ?                       # herdr's own binding list
                                 # (prefix is ctrl+g here, NOT upstream's ctrl+b —
                                 #  ctrl+b stays free for vim page-up, ctrl+a is
                                 #  WezTerm's leader. Upstream docs will disagree.)
  herdr server stop              # stop everything
VERIFY
