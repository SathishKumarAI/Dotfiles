# Worklog

## 2026-05-27 23:26 — Vetted skill marketplaces; set up /document workflow

**Summary:** Security-vetted two third-party Claude Code skill sources and stood up a session-documentation workflow — a `/document` skill plus a throttled Stop-hook reminder that writes to this file.

**Changes:**
- `~/.claude/skills/document/SKILL.md` — new `/document` skill: summarizes the session and appends a dated entry here.
- `~/.claude/hooks/worklog-reminder.sh` — new Stop hook: nudges to run `/document` when this file is stale (opt-in per project, throttled to 30 min).
- `~/.claude/settings.json` — added a `Stop` hook wiring the reminder (deny list untouched).
- `docs/WORKLOG.md` — this log.
- `CLAUDE.md` — recorded the vetted skill set and the documentation workflow.

**Decisions:**
- `alirezarezvani/claude-skills` (MIT, ~5.2k stars): hooks are read-only linters, no exfiltration. Installing only `engineering-skills`, `engineering-advanced-skills`, `skill-security-auditor` to avoid context bloat.
- `JuliusBrussee/caveman`: code clean, but the `curl|bash` installer is invasive (edits settings.json, auto-installs into every detected agent, registers an unvetted `caveman-shrink` MCP, unpinned to `main`). Chose the plain `claude plugin install caveman@caveman` path instead.
- Reminder via Stop hook (not full auto-doc) to avoid per-turn overhead; gated on `docs/WORKLOG.md` existing so it never nags in other projects.

**Follow-ups:**
- [ ] Run `bash ~/coding/scripts/install-claude-skills.sh` to install the plugins (Claude can't run `claude plugin` commands).
- [ ] Reconcile `~/.claude/settings.json` with chezmoi so the new `Stop` hook is tracked.
- [ ] Optionally track `~/.claude/skills/document/` and `~/.claude/hooks/worklog-reminder.sh` in chezmoi for cross-machine replication.
