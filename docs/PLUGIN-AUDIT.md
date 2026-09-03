# Claude Code Plugin Audit — 2026-07-31

Machine: Windows 11 (`C:\Users\PRANAS`). Config: `~/.claude/settings.json`.
30 plugins enabled, 1 disabled (`posthog`).

**How to use this file:** edit the `DECISION` column. Write `KEEP` or `OFF`.
When done, tell Claude "apply PLUGIN-AUDIT.md" and it will rewrite
`enabledPlugins` in `~/.claude/settings.json` (backup made first).

Cost columns explained:
- **Prompt cost** = tokens injected into the system prompt on *every message*,
  whether or not you use the plugin. Skill/agent descriptions live here.
- **Runtime cost** = hooks that execute per session or per message.
- Agent descriptions cost more per item than skill descriptions — they ship
  full multi-example blocks.

---

## Decision table

| # | Plugin | Contents | Prompt cost | Status / problem | Suggested | DECISION |
|---|---|---|---|---|---|---|
| 1 | `caveman` | 7 skills, 3 agents, 10 cmds, hooks | ~400 tok | working; SessionStart + UserPromptSubmit fire every message (intended) | KEEP |**KEEP** |
| 2 | `superpowers` | 14 skills, SessionStart hook | ~1.2k tok | working; hook injects full `using-superpowers` body verbatim each session (~700 tok) | KEEP |**KEEP** |
| 3 | `code-review` | 1 command | ~50 tok | working | KEEP |**KEEP** |
| 4 | `frontend-design` | 1 skill | ~80 tok | working | KEEP |**KEEP** |
| 5 | `skill-creator` | 1 skill | ~90 tok | working | KEEP |**KEEP** |
| 6 | `claude-md-management` | 1 skill, 1 cmd | ~100 tok | working | KEEP |**KEEP** |
| 7 | `plugin-dev` | 7 skills, 3 agents, 1 cmd | ~1.6k tok | working, but 3 verbose agents are expensive; only useful while authoring plugins | KEEP |**KEEP** |
| 8 | `mlflow` | 9 skills, 3 hooks | ~700 tok | working; **UserPromptSubmit hook fires on every message** | KEEP |**KEEP** |
| 9 | `typescript-lsp` | LSP | low | `node` present, works | KEEP |**KEEP** |
| 10 | `pyright-lsp` | LSP | low | **`pyright` binary MISSING** — install: `npm i -g pyright` | KEEP + install |**KEEP** |
| 11 | `huggingface-skills` | 25 skills, MCP | **~3k tok** | **biggest single prompt cost.** MCP sits unauthenticated (OAuth never run). Worth it only if you actually train/deploy on HF | your call |OFF |
| 12 | `gopls-lsp` | LSP | low | **`go` and `gopls` MISSING on this box** | OFF |OFF |
| 13 | `rust-analyzer-lsp` | LSP | low | **`rustc` MISSING on this box** | OFF |OFF |
| 14 | `lua-lsp` | LSP | low | **`lua-language-server` MISSING** | OFF |OFF |
| 15 | `github` | MCP (http) | low | **`GITHUB_PERSONAL_ACCESS_TOKEN` unset — MCP fails auth.** `gh` CLI already authenticated, covers same ground | OFF |OFF |
| 16 | `pinecone` | 9 skills, 1 cmd, SessionStart hook | ~800 tok | **`PINECONE_API_KEY` unset.** Nags at every session start | OFF |OFF |
| 17 | `qdrant-skills` | 11 skills | **~2.4k tok** | second-biggest prompt cost. Vector DB — keep at most one of Pinecone/Qdrant, and only if a repo uses it | OFF |OFF |
| 18 | `firecrawl` | 10 skills, 1 cmd | ~700 tok | MCP unauthenticated, `FIRECRAWL_API_KEY` unset | OFF |OFF |
| 19 | `exa` | 2 skills, MCP | ~200 tok | MCP stuck at `authenticate`, `EXA_API_KEY` unset. Overlaps built-in WebSearch | OFF |OFF |
| 20 | `sentry` | 7 skills, MCP | ~550 tok | MCP stuck at `authenticate`, `SENTRY_AUTH_TOKEN` unset. No Sentry project in workspace | OFF |OFF |
| 21 | `serena` | MCP (uvx) | low | clones from git on every start (slow). Overlaps LSP + Grep | OFF |OFF |
| 22 | `context7` | MCP (npx) | low | npx cold-start each session; unused in this workspace | OFF |OFF |
| 23 | `playwright` | MCP (npx) | low | npx cold-start; overlaps built-in `claude-in-chrome` | OFF |OFF |
| 24 | `chrome-devtools-mcp` | 6 skills | ~400 tok | overlaps built-in `claude-in-chrome` browser tools | OFF |OFF |
| 25 | `duckdb-skills` | 9 skills | ~250 tok | cheap, but unused unless doing local analytics | OFF |OFF |
| 26 | `pr-review-toolkit` | **6 agents**, 1 cmd | **~1.5k tok** | 4-way overlap with `code-review`, `caveman:cavecrew-reviewer`, built-in `/review` + `/security-review` | OFF |OFF |
| 27 | `agent-sdk-dev` | 2 agents, 1 cmd | ~300 tok | only useful when building Agent SDK apps | OFF |OFF |
| 28 | `mcp-server-dev` | 3 skills | ~350 tok | only useful when building MCP servers | OFF |OFF |
| 29 | `pydantic-ai` | 1 skill | ~100 tok | only if using pydantic-ai | OFF |OFF |
| 30 | `nvidia-skills` | 1 skill | ~30 tok | cheap; keep if you touch CUDA/Jetson/TensorRT | your call |OFF |
| 31 | `posthog` | **130 skills**, 1 agent, 6 cmds, 3 hooks | huge | **already disabled — leave it off.** Would add ~4k tok/prompt | leave OFF |OFF |

---

## Environment gaps (independent of keep/disable)

| Variable / binary | State | Needed by |
|---|---|---|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | unset | `github` MCP |
| `PINECONE_API_KEY` | unset | `pinecone` MCP |
| `EXA_API_KEY` | unset | `exa` |
| `FIRECRAWL_API_KEY` | unset | `firecrawl` |
| `SENTRY_AUTH_TOKEN` | unset | `sentry` |
| `pyright` | missing | `pyright-lsp` |
| `go` / `gopls` | missing | `gopls-lsp` |
| `rustc` | missing | `rust-analyzer-lsp` |
| `lua-language-server` | missing | `lua-lsp` |
| `node` `npx` `uv` `uvx` `python` | present | everything else |

Silence the Pinecone session-start nag without setting a key:

```powershell
setx PINECONE_SKIP_AUTH_CHECK 1
```

Set a key persistently on Windows (new shell picks it up; restart Claude Code after):

```powershell
setx GITHUB_PERSONAL_ACCESS_TOKEN "ghp_..."
```

---

## Redundancy map

| Job | Competing plugins | Note |
|---|---|---|
| Code review | `code-review`, `pr-review-toolkit`, `caveman:cavecrew-reviewer`, built-in `/review`, built-in `/security-review` | pick one, drop three |
| Browser control | `chrome-devtools-mcp`, `playwright`, built-in `claude-in-chrome` | built-in already loaded |
| Vector DB | `pinecone`, `qdrant-skills` | keep zero unless a live repo uses one |
| Code navigation | `serena`, the 5 `*-lsp` plugins, built-in Grep/Glob | LSP + Grep suffice |
| Web search | `exa`, `firecrawl`, built-in WebSearch/WebFetch | built-in covers most |

---

## Projected saving

Applying the suggested column (keep 11, disable 19):

- ~10–12k tokens removed from **every prompt of every session**
- Two hooks stop firing (`pinecone` SessionStart, plus fewer MCP cold-starts)
- 4 npx/uvx MCP servers stop spawning at session start — faster startup

`huggingface-skills` alone is ~3k tok/prompt. If ML work on HF is not active
right now, turning it off is the single largest win in the table.

---

## Apply

After filling the DECISION column, either:

1. Tell Claude: `apply PLUGIN-AUDIT.md` — it edits `~/.claude/settings.json`
   (`enabledPlugins` block only) and backs up to `settings.json.bak` first.
2. Or do it manually per plugin with `/plugin` in the Claude Code TUI.

Restart Claude Code after applying — plugin state loads at session start.

**APPLIED 2026-07-31.** 10 ON / 21 OFF. Backup: `~/.claude/settings.json.bak`.
Every plugin is listed explicitly (`false` rather than deleted) so re-enabling
is a one-character edit and nothing silently reappears on update.

---

# Operating guide — spend less, get more

## 1. The core model

A plugin costs tokens in three separate places. Know which one you are paying.

| Cost site | When charged | What sits there | How to shrink |
|---|---|---|---|
| System prompt | **every message, forever** | skill `description:` lines, agent descriptions, command names | disable the plugin — nothing else works |
| Tool schemas | on load | MCP tool JSON schemas | already deferred on this machine (see §2) |
| Hooks | per session or per message | hook script output injected as context | disable plugin, or set the plugin's opt-out env var |

Rule of thumb: **a plugin you use once a month but keep enabled costs more than
it saves.** Prompt cost is unconditional; usefulness is conditional.

## 2. Tool deferral is already ON — keep it that way

This machine loads MCP tool *names* only; full schemas load on demand via
`ToolSearch`. That is why 60+ MCP tools show up as names without their
parameter blocks. It saves several thousand tokens per session. Do not
disable it. Skill and agent *descriptions* are NOT deferred — those are the
ones you pay for unconditionally, which is why disabling beats hoping.

## 3. Per-project plugin sets — the real "auto enable / auto disable"

There is no built-in "disable if unused for N days". The supported mechanism is
**scoping**: keep the global set minimal, then turn heavy plugins on only inside
the repo that needs them.

Put an `enabledPlugins` block in the repo's own `.claude/settings.json`. It
layers on top of the user-level file, so you only list the deltas:

`~/coding/live/pickleball-vision-llm/.claude/settings.json`
```json
{
  "enabledPlugins": {
    "huggingface-skills@claude-plugins-official": true,
    "mlflow@claude-plugins-official": true
  }
}
```

`~/coding/workspace/dotfiles/.claude/settings.json`
```json
{
  "enabledPlugins": {
    "plugin-dev@claude-plugins-official": true,
    "skill-creator@claude-plugins-official": true
  }
}
```

Effect: HF's ~3k tokens/prompt are charged **only** in the vision repo, and
plugin-dev's ~1.6k only when authoring plugins. Everywhere else you run lean.

- Commit `.claude/settings.json` to the repo — the config travels with the work.
- Use `.claude/settings.local.json` (gitignored) for anything with a secret.
- Verify once after adding a project file: run `/plugin` in that repo and
  confirm the extra plugin shows as enabled there but not in a different repo.

## 4. Mid-session toggling

`/plugin` in the TUI enables/disables without editing JSON. Enabling mid-session
does not retroactively shrink context already sent, so the win is largest when
you toggle at the *start* of a session. Practical loop:

1. Start lean (current global set).
2. Hit a task that needs a heavy plugin → `/plugin` enable → `/clear` if the
   session is already long, so the new system prompt starts fresh.
3. Disable it again when the task ends, or leave it to the per-repo file in §3.

## 5. Measure, don't guess

- `/context` — real breakdown of what is eating the current window. Run it
  right after a `/clear` to see the *floor* cost of your plugin set.
- `/caveman-stats` — session token usage and cumulative savings from caveman
  compression, plus a USD figure.
- Re-run this audit after installing anything new. The failure mode is drift:
  plugins accumulate, nobody removes them.

## 6. Other levers, biggest first

| Lever | Saving | Cost to you |
|---|---|---|
| Keep the disabled set disabled | ~10–12k tok/prompt | none |
| Scope heavy plugins per repo (§3) | ~3–5k tok/prompt outside those repos | 5 min setup |
| `/clear` between unrelated tasks | resets accumulated history | lose conversation context |
| `/caveman ultra` for grunt work | ~40–60% on output tokens | terser answers |
| Delegate wide searches to `caveman:cavecrew-investigator` | ~60% vs raw file reads landing in main context | none |
| Prefer `Grep`/`Glob` over `cat`-ing whole files | large on big files | none |

## 7. Plugin-specific tuning notes

| Plugin | Note |
|---|---|
| `superpowers` | Its SessionStart hook re-injects the whole `using-superpowers` skill body each session (~700 tok). That is the design — it is what makes the skills fire reliably. Keep it unless you find the skills are not firing anyway. |
| `mlflow` | UserPromptSubmit hook runs on **every message**. Cheap today, but if MLflow work stops, this is the next one to cut. |
| `caveman` | Two hooks per message, but it is net-negative cost — output compression pays for the hooks many times over. |
| `pinecone` (off) | If ever re-enabled without a key, silence the session nag with `setx PINECONE_SKIP_AUTH_CHECK 1`. |
| `pyright-lsp` | Kept but non-functional until `npm i -g pyright`. Do that or turn it off — a broken LSP is pure cost. |
| `posthog` | 130 skills. Never enable globally. Per-repo only, if ever. |

## 8. Statusline (optional)

The caveman plugin ships a mode badge that is not wired up. Add to
`~/.claude/settings.json` if you want `[CAVEMAN]` visible:

```json
"statusLine": {
  "type": "command",
  "command": "powershell -ExecutionPolicy Bypass -File \"C:\\Users\\PRANAS\\.claude\\plugins\\cache\\caveman\\caveman\\0d95a81d35a9\\src\\hooks\\caveman-statusline.ps1\""
}
```
