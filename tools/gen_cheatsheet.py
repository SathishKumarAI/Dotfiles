#!/usr/bin/env python3
"""Generate the keybindings cheatsheet image (SVG + PNG).

Catppuccin Mocha themed. Layout sorted by how often you use each key, so the
image doubles as a memorization aid (Tier 1 = learn first).

Usage:
    python3 tools/gen_cheatsheet.py
    # writes assets/wezterm-cheatsheet.svg and (if rsvg-convert present) .png
"""
import os
import shutil
import subprocess
from html import escape

# --- Catppuccin Mocha palette ---
BASE = "#1e1e2e"
MANTLE = "#181825"
CRUST = "#11111b"
SURFACE0 = "#313244"
TEXT = "#cdd6f4"
SUBTEXT = "#a6adc8"
MUTED = "#7f849c"
GREEN = "#a6e3a1"
BLUE = "#89b4fa"
PEACH = "#fab387"
MAUVE = "#cba6f7"
TEAL = "#94e2d5"
SKY = "#89dceb"
YELLOW = "#f9e2af"
PINK = "#f5c2e7"
RED = "#f38ba8"

# --- Content: (title, accent, [(keys, action), ...]) ---
CARDS = [
    ("1 · DAILY — learn first", GREEN, [
        ("Ctrl+Alt+Space", "App launcher (rofi)"),
        ("Ctrl+Shift+D / E", "Split pane  H / V"),
        ("Ctrl+Shift+H J K L", "Move between panes"),
        ("Ctrl+Shift+T / W", "New / close tab"),
        ("Ctrl+Shift+C / V", "Copy / paste"),
    ]),
    ("2 · OFTEN", BLUE, [
        ("Ctrl+Tab", "Next tab"),
        ("Ctrl+Shift+Tab", "Previous tab"),
        ("Alt+1 .. 9", "Jump to tab N"),
        ("Ctrl+Shift+Enter", "Zoom (maximize) pane"),
        ("Ctrl+Shift+X", "Close pane"),
        ("Super+[ / ]", "Prev / next workspace"),
    ]),
    ("3 · WEEKLY", PEACH, [
        ("Ctrl+Shift+P", "Profiles (Bash/Zsh/Zellij)"),
        ("Ctrl+Shift+Z", "Zellij in new tab"),
        ("Ctrl+Shift+F", "Search scrollback"),
        ("Ctrl+Shift+Alt+H J K L", "Resize pane"),
        ("Ctrl+ + / - / 0", "Font  bigger / smaller / reset"),
    ]),
    ("4 · OCCASIONAL", MAUVE, [
        ("Ctrl+Shift+Alt+P", "Command palette"),
        ("Ctrl+Shift+PgUp/PgDn", "Scroll half page"),
        ("F11", "Fullscreen"),
        ("Ctrl+Click", "Open link under cursor"),
        ("Super+Q", "Close window (GNOME)"),
    ]),
    ("ROFI — launcher", PINK, [
        ("Ctrl+Alt+Space", "Open"),
        ("type...", "Fuzzy search (most-used first)"),
        ("Enter", "Launch selected"),
        ("Tab", "Switch mode (apps/run/win)"),
        ("Esc", "Close"),
    ]),
    ("ZELLIJ — prefix Ctrl+A", YELLOW, [
        ("Ctrl+A then H J K L", "Navigate panes"),
        ("Ctrl+A then N / P", "Next / prev tab"),
        ("Ctrl+A then C / X", "New / close pane"),
        ("Ctrl+A then D", "Detach session"),
        ("Ctrl+A then [", "Scroll mode"),
    ]),
]

FOOTER = ("GNOME Wayland: rofi + wezterm run on XWayland. rofi = "
          "env -u WAYLAND_DISPLAY rofi -normal-window (X11 backend + keyboard "
          "focus so Esc works); wezterm enable_wayland=false (explicit-sync).")

# --- Geometry ---
COLS = 2
CARD_W = 660
GAP = 36
PAD = 40
HEADER_H = 110
ROW_H = 46
CARD_HEAD = 58
CARD_PAD = 18
FOOT_H = 70

def card_height(card):
    return CARD_HEAD + CARD_PAD + len(card[2]) * ROW_H + CARD_PAD

# greedy column packing (balance by shortest column)
col_y = [HEADER_H + PAD] * COLS
placements = []
for card in CARDS:
    c = min(range(COLS), key=lambda i: col_y[i])
    x = PAD + c * (CARD_W + GAP)
    y = col_y[c]
    placements.append((x, y, card))
    col_y[c] = y + card_height(card) + GAP

W = PAD * 2 + COLS * CARD_W + (COLS - 1) * GAP
H = int(max(col_y)) + FOOT_H + PAD

def t(x, y, s, size, color, weight="normal", anchor="start", mono=False):
    fam = "JetBrains Mono, monospace" if mono else "Inter, Segoe UI, sans-serif"
    return (f'<text x="{x}" y="{y}" font-family="{fam}" font-size="{size}" '
            f'font-weight="{weight}" fill="{color}" text-anchor="{anchor}">'
            f'{escape(s)}</text>')

parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
         f'viewBox="0 0 {W} {H}">']
parts.append(f'<rect width="{W}" height="{H}" rx="24" fill="{CRUST}"/>')
parts.append(f'<rect x="8" y="8" width="{W-16}" height="{H-16}" rx="20" fill="{BASE}"/>')

# header
parts.append(t(PAD, 64, "Keybindings Cheatsheet", 44, TEXT, "700"))
parts.append(t(PAD, 96, "WezTerm · GNOME · Zellij · Rofi   —   sorted by how often you use it",
               22, SUBTEXT))
parts.append(t(W - PAD, 64, "Catppuccin Mocha", 22, MAUVE, "600", "end"))

# cards
for x, y, (title, accent, rows) in placements:
    ch = card_height((title, accent, rows))
    parts.append(f'<rect x="{x}" y="{y}" width="{CARD_W}" height="{ch}" rx="16" '
                 f'fill="{MANTLE}" stroke="{SURFACE0}" stroke-width="1"/>')
    parts.append(f'<rect x="{x}" y="{y}" width="6" height="{ch}" rx="3" fill="{accent}"/>')
    parts.append(t(x + 26, y + 40, title, 24, accent, "700"))
    ry = y + CARD_HEAD + CARD_PAD + 8
    for keys, action in rows:
        # keycap pill
        kw = 16 + len(keys) * 11.5
        parts.append(f'<rect x="{x+26}" y="{ry-26}" width="{kw:.0f}" height="34" rx="8" '
                     f'fill="{SURFACE0}"/>')
        parts.append(t(x + 26 + kw/2, ry - 2, keys, 18, TEXT, "600", "middle", mono=True))
        parts.append(t(x + 26 + kw + 18, ry - 2, action, 19, SUBTEXT))
        ry += ROW_H

# footer
fy = H - FOOT_H - PAD + 30
parts.append(f'<rect x="{PAD}" y="{fy-34}" width="{W-2*PAD}" height="56" rx="12" '
             f'fill="{MANTLE}" stroke="{RED}" stroke-width="1"/>')
parts.append(t(PAD + 20, fy, "⚠ " + FOOTER, 17, SUBTEXT))

parts.append("</svg>")
svg = "\n".join(parts)

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
assets = os.path.join(here, "assets")
os.makedirs(assets, exist_ok=True)
svg_path = os.path.join(assets, "wezterm-cheatsheet.svg")
png_path = os.path.join(assets, "wezterm-cheatsheet.png")
with open(svg_path, "w") as f:
    f.write(svg)
print("wrote", svg_path)

rsvg = shutil.which("rsvg-convert")
if rsvg:
    subprocess.run([rsvg, "-o", png_path, svg_path], check=True)
    print("wrote", png_path)
else:
    print("rsvg-convert missing; SVG only")
