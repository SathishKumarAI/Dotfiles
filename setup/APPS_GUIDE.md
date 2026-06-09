# Applications Guide — What's Installed and Why

## Installed Applications

### Coding & Development

| App | Install Method | Purpose | How to Launch |
|-----|---------------|---------|---------------|
| **VS Code** | Flatpak | Full IDE for Python, TypeScript, web dev | `flatpak run com.visualstudio.code` or app menu |
| **Neovim 0.12** | Binary | Terminal editor, fast, extensible | `nvim` or `v` (alias) |
| **Postman** | Flatpak | API testing and debugging | App menu |
| **DBeaver** | Flatpak | Database GUI (PostgreSQL, MySQL, SQLite, etc.) | App menu |
| **Podman Desktop** | Flatpak | Container management GUI (Docker alternative) | App menu |
| **lazygit** | Binary | Git operations in a terminal UI | `lg` (alias) |

### Documentation & Knowledge

| App | Install Method | Purpose | How to Launch |
|-----|---------------|---------|---------------|
| **Obsidian** | Flatpak | Markdown knowledge base with wiki-links | App menu, vault at `~/coding/DevVault/` |
| **Logseq** | Flatpak | Graph-based outliner (Obsidian alternative) | App menu |
| **draw.io** | Flatpak | Diagrams, flowcharts, architecture drawings | App menu |

### Productivity & Office

Installed via `bash setup/install-productivity.sh` (Flatpak/Flathub).

| App | Install Method | Purpose | How to Launch |
|-----|---------------|---------|---------------|
| **LibreOffice** | Flatpak | Full office suite — docs, spreadsheets, slides | `flatpak run org.libreoffice.LibreOffice` |
| **ONLYOFFICE** | Flatpak | Office suite with strong MS Office (docx/xlsx/pptx) fidelity | App menu |
| **Calibre** | Flatpak | E-book library management and format conversion | App menu |

### Focus / Deep Work

| App | Install Method | Purpose | How to Launch |
|-----|---------------|---------|---------------|
| **Solanum** | Flatpak | Pomodoro timer for focused work sessions | `flatpak run org.gnome.Solanum` |
| **Flameshot** | Flatpak | Screenshot + annotation, handy for docs/notes | App menu / bind to PrtSc |
| **Joplin** | Flatpak | Markdown note-taking for session capture | App menu |

---

## Why Each App

### VS Code
Your projects span Python, TypeScript, Jupyter, HTML, Dart. VS Code handles all of them with extensions. The Flatpak version auto-updates and is sandboxed.

**First-launch setup:**
1. Install extensions: Python, Pylance, ESLint, Prettier, GitLens, Docker
2. Set terminal to use mise-managed runtimes (may need path config for Flatpak)

### Neovim
For quick edits, git commits, SSH sessions, and when you want speed. The init.lua we set up has sensible defaults — add plugins via lazy.nvim when ready.

### Postman
Test your RAG API endpoints, Bedrock integrations, and any REST/GraphQL APIs during development. Save collections per project.

### DBeaver
Visual database browser. Connect to PostgreSQL, MySQL, SQLite databases your projects use. Run queries, browse tables, export data.

### Podman Desktop
Rocky Linux ships with Podman (Docker-compatible). Podman Desktop gives you a GUI to manage containers, images, and pods. No Docker daemon needed.

### Obsidian
Your dev knowledge base. All notes are plain Markdown with `[[wiki-links]]`. Git-syncable. The vault at `~/coding/DevVault/` has tool docs, project indexes, and daily note templates pre-built.

**Vault structure:**
```
DevVault/
├── Home.md              # Dashboard
├── daily/               # Daily dev logs
├── projects/            # Per-project notes
│   └── Project Index.md # All 32 repos listed
├── tools/               # Tool documentation
│   ├── Tool Index.md    # All tools listed
│   ├── mise.md          # mise guide
│   ├── chezmoi.md       # chezmoi guide
│   └── Obsidian.md      # Obsidian guide
├── templates/           # Note templates
│   ├── Daily Note.md
│   └── Project Note.md
└── assets/              # Images, diagrams
```

### Logseq
Alternative to Obsidian with a different philosophy — outliner-first instead of document-first. Good for daily journals, meeting notes, and quick capture. Try both, keep the one that fits your brain.

### draw.io
Architecture diagrams, flowcharts, system design drawings. Export as PNG/SVG for README files or Obsidian notes. Useful for your system-design-interview-prep repo.

---

## Workflow CLI Tools

Installed via `bash setup/install-workflow-tools.sh` — OS-independent (detects
dnf/pacman/apt/zypper/brew, falls back to cargo/uv/go/gh). Idempotent.

| Tool | Replaces / adds | Purpose |
|------|-----------------|---------|
| **zoxide** | `cd` | Jump to frecent dirs: `z proj` |
| **atuin** | Ctrl-R history | Searchable, syncable shell history |
| **fzf** | — | Fuzzy finder powering file/branch/history pickers |
| **yazi** | `ranger` | Fast terminal file manager |
| **tealdeer** (`tldr`) | `man` | Practical command examples |
| **delta** | git diff pager | Side-by-side, syntax-highlighted diffs |
| **direnv** | — | Auto-load per-project env on `cd` |
| **just** | `make` | Project command runner |
| **pre-commit** | — | Lint/format git hooks |
| **lazydocker** | docker CLI | TUI for containers/images |
| **gh-dash** | — | GitHub PR/issue dashboard (gh extension) |
| **entr** | — | Run a command when files change |
| **jq** | — | JSON query/transform |
| **yq** | — | YAML/TOML query/transform |
| **xh** | `curl`/httpie | Fast, friendly HTTP client |
| **uv** | pip + venv | Ultra-fast Python package/venv manager |
| **ruff** | flake8 + black | Python lint + format (one fast binary) |
| **btop** | `top` | Resource monitor (CPU/GPU/mem) |
| **dust** | `du` | Intuitive disk-usage tree |
| **hyperfine** | `time` | Statistical CLI benchmarking |
| **procs** | `ps` | Modern process viewer |
| **duf** | `df` | Friendly disk-free overview |

### Tier 2 — data, local AI & extras

| Tool | Purpose |
|------|---------|
| **visidata** (`vd`) | Interactive TUI for CSV/Parquet/JSON/SQLite |
| **csvlens** | `less` for CSV files |
| **duckdb** | In-process SQL over CSV/Parquet/JSON |
| **miller** (`mlr`) | awk/sed/cut for CSV/JSON pipelines |
| **ollama** | Run local LLMs (Llama/Mistral/…) |
| **llm** | CLI for querying models, logs to SQLite |
| **nvtop** | GPU monitor (Linux + GPU) |
| **glow** | Render Markdown in the terminal |
| **gum** | Pretty prompts/menus for shell scripts |
| **navi** | Interactive cheatsheets (Ctrl-G) |
| **watchexec** | Re-run commands on file change |
| **git-cliff** | Generate changelogs from commits |
| **croc** | Secure machine-to-machine file transfer |

**Shell wiring** (add to chezmoi-managed bashrc/zshrc):
```bash
eval "$(zoxide init bash)"
eval "$(atuin init bash)"
eval "$(direnv hook bash)"
# ~/.gitconfig: [core] pager = delta
```

---

## Validating the install

After running `setup.sh` (or any installer), check everything landed:

```bash
bash setup/validate-install.sh          # PASS/FAIL/WARN per tool + app, logs result
bash setup/validate-install.sh --fix     # re-run idempotent installers for anything missing, then re-check
bash setup/validate-install.sh --quiet    # summary only
```

- Read-only by default (no sudo); `--fix` re-runs the installers (sudo).
- Exit code `0` only when nothing failed — usable in CI / a Stop hook.
- Optional/hardware-dependent tools (e.g. `nvtop`, needs a GPU) report **WARN**, not FAIL.
- Logs are written to `setup/logs/validate-<timestamp>.log` (gitignored).
- `setup.sh` runs this automatically as its final step.

---

## Managing Flatpak Apps

```bash
# List installed apps
flatpak list --app

# Update all apps
flatpak update -y

# Run an app
flatpak run md.obsidian.Obsidian
flatpak run com.visualstudio.code

# Uninstall an app
flatpak uninstall md.obsidian.Obsidian

# Search for more apps
flatpak search <keyword>
```
