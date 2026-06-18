# Dev Workflow

How work flows on this machine. See also: [MACHINE-CHEATSHEET](MACHINE-CHEATSHEET.md) · [CLAUDE-CODE-GUIDE](CLAUDE-CODE-GUIDE.md).

## New project bootstrap
```sh
mkdir -p ~/coding/<name> && cd ~/coding/<name>
git init
gh repo create SathishKumarAI/<name> --private --source=. --remote=origin
mise use python@3.12        # or node@lts, etc. — writes .mise.toml
direnv allow                # if using .envrc for per-dir env
# copy reusable docs/prompts:
cp ~/coding/docs/templates/doc-skeleton.md docs/
# frontend? copy the starter:
cp -r ~/coding/docs/templates/ai-friendly-starter/* .
```

## Git / GitHub
- TUI: **lazygit** (`lazygit`) — stage/commit/branch/push visually.
- Diffs use **delta** (configured pager). `git diff`, `git show` are syntax-highlighted.
```sh
gh repo clone SathishKumarAI/<name>
gh pr create --fill          # PR from current branch
gh pr status
git switch -c feat/<thing>   # branch before committing (never commit on main)
```
Commit only when asked. Branch off `main`. Per workspace rules: create `.sh` scripts
for anything needing sudo rather than pasting long commands.

## Terminal multiplexing
- **WezTerm** is the terminal; leader = `Ctrl+a`. Splits, zoom, pane-picker, workspaces, resize key-table. Launches maximized. Full keys: `Dotfiles/docs/terminal/wezterm.mdx`.
- **zellij** for session multiplexing inside a pane when needed.

## Editing
- **neovim** (`nvim`), space leader. Primary editor.
- **VS Code** (Flatpak) for heavier GUI work / extensions.

## Python / data
- Active interpreter is **miniforge** (`~/miniforge3/bin/python`). Use conda envs or `mise`/`uv` per project — be explicit which, since mise's python shows "missing".
```sh
conda create -n <env> python=3.12 && conda activate <env>
# or per-project with mise:
mise use python@3.12
```

## Theme
Catppuccin Mocha everywhere (terminal, editor, prompt). Keep it consistent (workspace rule).

## Document your work
Run `/document` (Claude Code skill) at task end → appends a dated entry to the repo's
`docs/WORKLOG.md`. A Stop hook reminds you. See CLAUDE-CODE-GUIDE.
