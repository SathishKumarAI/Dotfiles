# Claude Code — Setup & Usage on This Machine

How Claude Code is configured here, and the skills/hooks available. See workspace
`~/coding/CLAUDE.md` for the authoritative source.

## Skills (invoke with `/<name>`)
- **`/document`** — appends a dated entry to `docs/WORKLOG.md`. Run at task/session end.
- **`/code-review`** — review the current diff (low→max effort; `ultra` = cloud multi-agent). `--comment` posts inline PR comments, `--fix` applies findings.
- **`/simplify`** — quality-only cleanup of changed code (reuse/efficiency), applies fixes.
- **`/verify`, `/run`** — run the app to confirm a change works.
- **`/security-review`** — security pass on branch changes.
- **caveman** (`/caveman lite|full|ultra`) — ultra-compressed responses to save tokens. `stop caveman` / `normal mode` to exit. `/caveman-commit`, `/caveman-review`, `/caveman-compress`, `/caveman-stats`.
- **engineering-skills / engineering-advanced-skills** — large catalog (architects, reviewers, security, cloud, data, frontend). Auto-suggested by task.
- **superpowers** — brainstorming, writing-plans, TDD, systematic-debugging, code-review workflows.

## Marketplaces
- `alirezarezvani/claude-skills` (registers as `claude-code-skills`)
- `JuliusBrussee/caveman`
- Vetted set installed via `bash ~/coding/scripts/install-claude-skills.sh`:
  caveman, engineering-skills, engineering-advanced-skills, skill-security-auditor.

## Install gotchas (from CLAUDE.md)
- Install **caveman** via plugin path: `claude plugin install caveman@caveman` — NOT the `curl|bash` one-liner (it edits settings.json + adds an unvetted MCP).
- `engineering-advanced-skills` ships a **PreToolUse hook** warning/blocking edits with `pickle`/`eval`/f-string SQL. Set `ENABLE_SECURITY_REMINDER=0` if it interrupts ML work.

## Hooks active
- **Stop hook** `~/.claude/hooks/worklog-reminder.sh` (throttled) — reminds you to `/document` at task end.
- **SessionStart** — caveman mode + superpowers skill bootstrap.

## Reusable templates (cross-repo)
- `~/coding/docs/templates/` — Anthropic-style doc skeletons + prompt-engineering templates.
  - `doc-skeleton.md`, `prompt-skeleton.md`, `README.md` (house style).
  - `prompts/` — ready prompts: code-review, debug-issue, plan-feature, write-docs, commit-and-pr.
  - `ai-friendly-starter/` — frontend starter (see its README).

## Settings / customization
- Use the **`/update-config`** skill for settings.json changes (permissions, env vars, hooks).
- Use **`/keybindings-help`** to customize `~/.claude/keybindings.json`.
- MCP servers available via ToolSearch: context7 (live library docs), chrome-devtools, vercel, Google (Gmail/Calendar/Drive).

## MCP: context7 for library docs
When working with any library/framework, prefer context7 over memory for current API
docs (`resolve-library-id` → `query-docs`). Covers React, Next.js, etc.
