# Agent Tools — How to Use

Practical first-run recipes for the tools installed 2026-06-29. Reference (what each
*is* + security) lives in
[`ai-coding/agent-cli-toolkit.mdx`](../ai-coding/agent-cli-toolkit.mdx); this page is
the *how to drive them*.

> **Safety rule for every agent tool below:** they run agents with **full
> permissions** and commit/push on their own. Always point them at a **branch or
> worktree**, never a dirty `main`. Read a tool's prompt/config before first real use.

---

## 1. skills CLI — manage agent skills

```sh
npx skills ls -g                       # what's installed (global)
npx skills find worktree               # search the ecosystem
npx skills add <owner>/<repo> -g -a claude-code -y   # install to Claude Code
npx skills remove <skill> -g           # uninstall
npx skills update -g                    # update all global skills
```

The agent id is `claude-code` (not `claude`). `-g` = user-global, `-y` = no prompts.

## 2. AXI — agent-ergonomic CLIs

Already-built AXI tools run with zero install:

```sh
npx -y gh-axi <task>               # GitHub ops (issues, PRs) token-cheaply
npx -y chrome-devtools-axi <task>  # browser automation
```

The `axi` **skill** guides Claude when you ask it to *build or review an agent-facing
CLI* — just say so and it applies the 10 AXI principles.

## 3. lavish — review HTML artifacts from an agent

When Claude produces a plan/diagram/diff as HTML, lavish opens it locally to annotate
and send feedback back. The skill auto-suggests it; manual:

```sh
npx -y lavish-axi open <file.html>   # open in browser, annotate, return notes
```

## 4. treehouse — instant isolated worktrees

```sh
treehouse --help                  # see commands
treehouse new                     # grab a clean worktree from the pool
treehouse list                    # what's checked out / leased
treehouse reset                   # recycle a worktree back to the pool
```

Use it to hand each agent its own checkout (deps + build cache preserved) instead of
re-cloning. Pairs with [agent-workflows](../ai-coding/agent-workflows.mdx).

## 5. gnhf — overnight autonomous loop

```sh
cd <your-repo>
git switch -c gnhf/<objective>     # ALWAYS a dedicated branch — it commits itself
gnhf --help
gnhf "Refactor X to Y; keep tests green"   # runs iterations until done/limit
```

Each iteration = one small committed, documented change; failures roll back; progress
is tracked in `notes.md`. Check `notes.md` and `git log` in the morning.

## 6. no-mistakes — pre-push validation gate

One-time per repo:

```sh
no-mistakes doctor                 # verify git + an agent binary present
cd <your-repo> && no-mistakes init # configure the real push target (e.g. origin)
```

Then push **to no-mistakes instead of origin**:

```sh
git push no-mistakes <branch>      # spins a disposable worktree, runs
                                   # review→tests→lint→docs, then forwards + opens PR
```

Or from inside Claude: `/no-mistakes` to gate/ship the current change.

## 7. firstmate — supervised agent fleet (tmux)

```sh
tmux new -s fleet                          # start inside tmux (crew windows show here)
cd ~/coding/tools/firstmate && claude      # the "first mate" takes over (AGENTS.md)
```

Then tell the first mate what to do; it spawns crew agents (each its own tmux window +
worktree) for *ship* (PR) or *scout* (report) tasks. Needs `gh` auth + tmux (present).

## 8. Speech Note — offline voice-to-text

```sh
flatpak run net.mkiol.SpeechNote
```

First run: **Settings → Languages** → download a Whisper model (`tiny`/`base` = fast
on the HDD; `small`/`medium` = more accurate). Then record from mic or drop an audio
file to transcribe. 100% offline. Full options + global-hotkey alternatives:
[`desktop/voice-dictation.mdx`](../desktop/voice-dictation.mdx).

---

## Typical combined flow

```
tmux → firstmate            # supervise a crew
  └ treehouse new           # each agent gets an isolated worktree
      └ agent does the work
          └ lavish          # review its HTML output
          └ git push no-mistakes <branch>   # gate before it ships
```

Or solo + overnight: `gnhf "<objective>"` on a dedicated branch, review in the morning.
