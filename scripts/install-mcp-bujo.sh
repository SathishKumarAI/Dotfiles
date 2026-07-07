#!/usr/bin/env bash
# Vetted MCP server installers for bujo frontend work.
# REVIEW before running. MCP servers load at the NEXT Claude Code start.
#   Run:  bash ~/coding/scripts/install-mcp-bujo.sh
#   List: claude mcp list      Remove: claude mcp remove <name>
set -euo pipefail

cd "$HOME/coding/bujo"

echo "==> 1/3 shadcn/ui MCP (official shadcn CLI) — component registry reference. No API key."
# Project scope → writes .mcp.json in this repo.
claude mcp add shadcn --scope project -- npx -y shadcn@latest mcp

echo "==> 2/3 Chrome DevTools MCP (Google) — perf / a11y / console / Lighthouse. No API key."
echo "    Needs Chrome. The server launches/attaches to Chrome itself."
claude mcp add chrome-devtools --scope project -- npx -y chrome-devtools-mcp@latest

echo "==> 3/3 Magic MCP (21st.dev) — AI UI component generation. NEEDS an API key."
echo "    Get a key at https://21st.dev, then run this (user scope, key stays out of the repo):"
echo '    claude mcp add magic --scope user --env API_KEY="YOUR_KEY" -- npx -y @21st-dev/magic@latest'
# Left commented so no half-configured server without a key:
# claude mcp add magic --scope user --env API_KEY="YOUR_KEY" -- npx -y @21st-dev/magic@latest

echo
echo "Done. RESTART Claude Code so the servers load. Then: claude mcp list"
echo "Note: shadcn-ui in this app is optional — it uses a custom Tailwind v4 + Catppuccin kit."
echo "The shadcn MCP is for referencing/generating components; it won't change existing UI."
