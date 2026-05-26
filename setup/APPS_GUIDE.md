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
