# Obsidian

**What:** Markdown-based knowledge base with bidirectional linking.
**Vault location:** `~/coding/DevVault/`
**Install:** Flatpak (`md.obsidian.Obsidian`)

## Why We Use It
- All notes are plain Markdown files (future-proof, works with git)
- `[[wiki-links]]` connect notes into a knowledge graph
- Works offline, no cloud dependency
- Plugins for diagrams, kanban, templates, git sync

## Vault Structure
```
DevVault/
├── Home.md              # Landing page
├── daily/               # Daily dev logs
├── projects/            # Per-project notes
├── tools/               # Tool documentation (you're here)
├── templates/           # Note templates
└── assets/              # Images, diagrams
```

## Recommended Plugins
After opening vault in Obsidian, install these community plugins:
- **Dataview** — Query your notes like a database
- **Templater** — Dynamic note templates
- **Git** — Auto-commit vault to GitHub
- **Excalidraw** — Draw diagrams inside notes
- **Kanban** — Project boards from markdown
- **Calendar** — Navigate daily notes
- **Advanced Tables** — Better markdown table editing

## Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| `Ctrl+O` | Quick open file |
| `Ctrl+P` | Command palette |
| `Ctrl+E` | Toggle edit/preview |
| `Ctrl+K` | Insert link |
| `[[` | Create wiki link |
| `Ctrl+Shift+F` | Search across vault |

## Sync With Git
```bash
cd ~/coding/DevVault
git init
git add -A && git commit -m "initial vault"
# Push to a private GitHub repo for cross-machine sync
```

#tools #obsidian #documentation
