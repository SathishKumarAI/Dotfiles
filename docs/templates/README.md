# Reusable Doc & Prompt Templates (machine-wide)

Professional, Anthropic-style documentation and prompt templates meant to be
**reused across every repo on this machine**. Copy a template into a project and
fill it in, or paste a prompt straight into Claude.

Referenced from `~/coding/CLAUDE.md` so Claude Code picks them up in any repo.

## Contents

| File | Purpose |
|------|---------|
| [`doc-skeleton.md`](doc-skeleton.md) | Structure for any project doc (README section, design doc, runbook) |
| [`prompt-skeleton.md`](prompt-skeleton.md) | The prompt-engineering structure all prompts here follow |
| [`prompts/code-review.md`](prompts/code-review.md) | Rigorous, prioritized code review of a diff |
| [`prompts/debug-issue.md`](prompts/debug-issue.md) | Systematic root-cause debugging |
| [`prompts/plan-feature.md`](prompts/plan-feature.md) | Turn a feature request into a concrete implementation plan |
| [`prompts/feature-template.md`](prompts/feature-template.md) | Build a known feature right: explore→plan→acceptance criteria→constraints→done-when |
| [`prompts/write-docs.md`](prompts/write-docs.md) | Generate clear docs for existing code |
| [`prompts/commit-and-pr.md`](prompts/commit-and-pr.md) | Clean commit messages + PR description |
| [`prompts/build-keybindings-cheatsheet.md`](prompts/build-keybindings-cheatsheet.md) | Build an all-apps keyboard cheatsheet from real configs + render PDF |

## How to use

- **In a repo:** `cp ~/coding/docs/templates/doc-skeleton.md docs/SOMETHING.md`
  and fill it in. For prompts, open the file and paste into Claude, replacing the
  `{{...}}` placeholders.
- **With Claude Code:** just reference them, e.g. "use the code-review template"
  — they're discoverable via `~/coding/CLAUDE.md`.

## House style (Anthropic-style docs)

1. **Lead with the point.** First sentence says what this is and why it exists.
2. **Scannable structure.** Short sections, descriptive headers, tables over
   prose for options/comparisons.
3. **Show, don't tell.** Concrete runnable commands and before/after examples.
4. **State the why.** Document the reason behind non-obvious choices, not just
   the what.
5. **One source of truth.** Link to the canonical place instead of duplicating.
