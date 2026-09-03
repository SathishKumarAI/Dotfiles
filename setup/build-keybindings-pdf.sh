#!/usr/bin/env bash
# build-keybindings-pdf.sh — render docs/keybindings-cheatsheet.mdx into a styled,
# print-ready PDF (Catppuccin Mocha + JetBrainsMono Nerd Font) via pandoc + Chrome.
# Single source: the MDX. Re-run after editing the cheatsheet.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MDX="$ROOT/docs/keybindings-cheatsheet.mdx"
OUT_PDF="$ROOT/assets/keybindings-cheatsheet.pdf"
WORK="$ROOT/.build-keybindings"
mkdir -p "$WORK"
TMP_HTML="$WORK/page.html"
BODY_MD="$WORK/body.md"
BODY_HTML="$WORK/body.html"
trap 'rm -rf "$WORK"' EXIT

command -v python3 >/dev/null || { echo "need python3" >&2; exit 1; }
CHROME="$(command -v google-chrome || command -v chromium || command -v chromium-browser || true)"
[ -n "$CHROME" ] || { echo "need chrome/chromium for PDF" >&2; exit 1; }

# md -> html fragment via the self-contained converter (no pandoc dependency).
python3 "$ROOT/setup/md2html.py" < "$MDX" > "$BODY_HTML"

CATPPUCCIN_CSS='
:root{--base:#1e1e2e;--mantle:#181825;--crust:#11111b;--text:#cdd6f4;
--subtext:#a6adc8;--surface0:#313244;--surface1:#45475a;--overlay:#6c7086;
--blue:#89b4fa;--green:#a6e3a1;--mauve:#cba6f7;--peach:#fab387;--yellow:#f9e2af;
--red:#f38ba8;--teal:#94e2d5;}
*{box-sizing:border-box}
html{-webkit-print-color-adjust:exact;print-color-adjust:exact}
body{background:var(--base);color:var(--text);margin:0;padding:28px 34px;
font-family:"JetBrainsMono Nerd Font","JetBrains Mono",ui-monospace,monospace;
font-size:10.5px;line-height:1.45;columns:2;column-gap:26px;}
h1{column-span:all;color:var(--mauve);font-size:21px;border-bottom:2px solid var(--mauve);
padding-bottom:6px;margin:0 0 10px}
h2{color:var(--blue);font-size:13px;margin:14px 0 5px;border-left:3px solid var(--blue);
padding-left:7px;break-after:avoid}
h3{color:var(--teal);font-size:11px;margin:9px 0 3px;break-after:avoid}
hr{border:0;border-top:1px solid var(--surface1);column-span:all;margin:12px 0}
p{margin:4px 0;color:var(--subtext)}
a{color:var(--blue);text-decoration:none}
strong{color:var(--peach)}
blockquote{border-left:3px solid var(--yellow);background:var(--mantle);margin:6px 0;
padding:4px 9px;color:var(--subtext);border-radius:0 4px 4px 0}
code{background:var(--crust);color:var(--green);padding:1px 4px;border-radius:3px;
font-size:9.5px;white-space:nowrap}
pre{background:var(--crust);border:1px solid var(--surface1);border-radius:5px;
padding:8px;overflow:auto;break-inside:avoid}
pre code{background:none;white-space:pre;color:var(--text)}
table{border-collapse:collapse;width:100%;margin:5px 0;break-inside:avoid;
background:var(--mantle);border-radius:5px;overflow:hidden}
th{background:var(--surface0);color:var(--mauve);text-align:left;padding:4px 7px;
font-size:9.5px;border-bottom:1px solid var(--surface1)}
td{padding:3px 7px;border-bottom:1px solid var(--surface0);vertical-align:top}
td:first-child code,td code:first-child{color:var(--yellow)}
tr:last-child td{border-bottom:none}
@page{size:A4;margin:10mm}
'

{
  printf '<!DOCTYPE html><html><head><meta charset="utf-8"><style>%s</style></head><body>\n' "$CATPPUCCIN_CSS"
  cat "$BODY_HTML"
  printf '\n</body></html>\n'
} > "$TMP_HTML"

echo "==> rendering PDF via $CHROME"
"$CHROME" --headless=new --disable-gpu --no-sandbox \
  --virtual-time-budget=10000 --run-all-compositor-stages-before-draw \
  --no-pdf-header-footer --print-to-pdf="$OUT_PDF" \
  "file://$TMP_HTML" 2>/dev/null

echo "==> wrote $OUT_PDF"
ls -lh "$OUT_PDF"
