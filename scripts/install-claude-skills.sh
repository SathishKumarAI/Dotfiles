#!/usr/bin/env bash
# install-claude-skills.sh
# Install the vetted Claude Code skill marketplaces + plugins.
#
# Vetted 2026-05-27 — see ~/coding/docs/WORKLOG.md for the security-review notes.
# These are `claude` CLI commands and may prompt for trust/confirmation, so run
# them yourself in an interactive terminal (Claude Code cannot run them):
#
#   bash ~/coding/scripts/install-claude-skills.sh
#
# Idempotent: re-running is safe; already-added marketplaces / installed plugins
# are skipped (the command reports it and the script continues).

set -uo pipefail

run() {
  echo "+ $*"
  "$@" || echo "  (continuing — likely already added/installed)"
}

echo "== caveman — plugin path, NOT the curl|bash installer =="
echo "   (the one-liner edits settings.json, auto-installs into every detected"
echo "    agent, and adds an unvetted caveman-shrink MCP — we avoid all of that)"
run claude plugin marketplace add JuliusBrussee/caveman
run claude plugin install caveman@caveman

echo
echo "== alirezarezvani/claude-skills — narrowed set for ML/Python work =="
run claude plugin marketplace add alirezarezvani/claude-skills
run claude plugin install engineering-skills@claude-code-skills
run claude plugin install engineering-advanced-skills@claude-code-skills
run claude plugin install skill-security-auditor@claude-code-skills

echo
echo "Done. Review what got installed:  claude plugin list"
echo
echo "Heads-up: engineering-advanced-skills ships a PreToolUse hook that warns/blocks"
echo "edits containing pickle / eval / f-string SQL. If it interrupts ML work, disable"
echo "it with:  export ENABLE_SECURITY_REMINDER=0   (add to your shell rc to persist)"
