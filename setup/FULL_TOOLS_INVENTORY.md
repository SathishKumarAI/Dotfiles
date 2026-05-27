# Full Tools Inventory — 60+ Dev Tools

**Machine:** Rocky Linux 10.1 x86_64
**Updated:** 2026-05-26

---

## Frontend Development

| Tool | Version | Install | Purpose |
|------|---------|---------|---------|
| **Node.js** | 24.16.0 | mise | JavaScript runtime |
| **npm** | 11.13.0 | mise | Node package manager |
| **yarn** | 1.22.22 | npm global | Alt package manager |
| **pnpm** | 11.3.0 | npm global | Fast package manager (hard links) |
| **Bun** | 1.3.14 | install script | Ultra-fast JS runtime + bundler + test runner |
| **Vite** | 8.0.14 | npm global | Next-gen frontend build tool |
| **Storybook** | 10.4.1 | npm global | Component library & UI documentation |
| **Playwright** | 1.60.0 | npm global | Browser testing, screenshots, E2E tests |
| **create-next-app** | — | npm global | Scaffold Next.js projects |

**How to start a frontend project:**
```bash
# React + Vite
npm create vite@latest my-app -- --template react-ts

# Next.js
npx create-next-app@latest my-app

# With Bun (faster)
bun create vite my-app --template react-ts
```

---

## Backend Development (Python)

| Tool | Version | Install | Purpose |
|------|---------|---------|---------|
| **Python** | 3.12.13 | mise | Language runtime |
| **FastAPI** | 0.136.3 | pip | Modern async API framework |
| **uvicorn** | 0.48.0 | pip | ASGI server for FastAPI |
| **Flask** | 3.1.3 | pip | Lightweight web framework |
| **Django** | 6.0.5 | pip | Full-stack web framework |
| **Celery** | 5.6.3 | pip | Distributed task queue |
| **Poetry** | 2.4.1 | pip | Dependency management + packaging |
| **Ruff** | 0.15.14 | pip | Ultra-fast Python linter + formatter |
| **httpie** | 3.2.4 | pip | Human-friendly HTTP client |

**How to start a backend project:**
```bash
# FastAPI
mkdir my-api && cd my-api
poetry init && poetry add fastapi uvicorn[standard]
# Create main.py with:
# from fastapi import FastAPI
# app = FastAPI()
uvicorn main:app --reload

# Django
django-admin startproject mysite
cd mysite && python manage.py runserver

# Flask
flask --app hello run --debug
```

---

## Backend Development (Node/TypeScript)

| Tool | Version | Install | Purpose |
|------|---------|---------|---------|
| **tsx** | 4.22.3 | npm global | Run TypeScript directly (no compile step) |
| **Prisma** | 7.8.0 | npm global | TypeScript ORM for PostgreSQL/MySQL/SQLite |

**How to use:**
```bash
# Run TypeScript without compiling
tsx my-script.ts

# Prisma setup
npx prisma init
npx prisma migrate dev
npx prisma studio  # visual DB browser
```

---

## Languages & Runtimes

| Tool | Version | Install | Purpose |
|------|---------|---------|---------|
| **Python** | 3.12.13 | mise | AI/ML, web, scripts |
| **Node.js** | 24.16.0 | mise | Web dev, TypeScript |
| **Go** | 1.26.3 | mise | CLI tools, infrastructure |
| **Rust** | 1.95.0 | mise | High-performance tools, systems |
| **Bun** | 1.3.14 | binary | Fast JS/TS runtime alternative |

All managed by mise — switch versions per-project with `.mise.toml`.

---

## Databases

| Tool | Version | Install | Purpose |
|------|---------|---------|---------|
| **mongosh** | 2.5.0 | binary | MongoDB shell (NoSQL) |
| **DBeaver** | 26.0.5 | Flatpak | Universal database GUI |
| **Prisma Studio** | — | npx | Visual DB browser for Prisma projects |
| **psql** | — | `sudo dnf install postgresql` | PostgreSQL CLI client |
| **sqlite3** | — | `sudo dnf install sqlite` | SQLite CLI |
| **mysql** | — | `sudo dnf install mariadb` | MySQL/MariaDB CLI client |
| **redis-cli** | — | `sudo dnf install redis` | Redis CLI |

---

## Docker & Containers

| Tool | Version | Install | Purpose |
|------|---------|---------|---------|
| **Podman** | 5.6.0 | dnf (pre-installed) | Docker-compatible, rootless containers |
| **Podman Desktop** | 1.27.2 | Flatpak | Container management GUI |
| **Docker** | — | `sudo dnf install docker-ce` | Container runtime (needs repo setup) |
| **lazydocker** | 0.25.2 | binary | Docker/Podman TUI (like lazygit for containers) |
| **ctop** | 0.7.7 | binary | Real-time container metrics (htop for containers) |
| **dive** | 0.13.1 | binary | Explore Docker image layers, find wasted space |

**How to use:**
```bash
# Podman (Docker-compatible, already works)
podman run -it python:3.12 bash
podman compose up -d

# lazydocker
lazydocker    # visual container management

# dive (analyze image layers)
dive my-image:latest

# ctop (live container monitoring)
ctop
```

---

## Flashcard & Learning Tools

| Tool | Version | Install | Purpose |
|------|---------|---------|---------|
| **Anki** | 25.09.04 | Flatpak | Spaced repetition flashcards (gold standard) |
| **Obsidian** | 1.12.7 | Flatpak | Markdown knowledge base (add Spaced Repetition plugin) |
| **Logseq** | 0.10.15 | Flatpak | Graph-based outliner/notes |

**How to use Anki for coding:**
1. Open Anki from app menu
2. Create deck: "Python", "System Design", "ML Concepts"
3. Add cards with code snippets on front, explanation on back
4. Review daily — Anki schedules reviews using spaced repetition
5. Sync across devices with AnkiWeb (free account)

**Obsidian Spaced Repetition:**
1. Open Obsidian vault (`~/coding/DevVault/`)
2. Settings > Community Plugins > Browse > Search "Spaced Repetition"
3. Install and enable
4. Add flashcards in any note:
```markdown
What does `git rebase` do?
?
Replays commits from one branch on top of another, creating a linear history.
```

---

## DevOps & Infrastructure

| Tool | Version | Install | Purpose |
|------|---------|---------|---------|
| **Terraform** | 1.15.4 | binary | Infrastructure as Code (AWS, GCP, Azure) |
| **kubectl** | 1.36.1 | binary | Kubernetes cluster management |
| **k9s** | 0.50.18 | binary | Kubernetes TUI (visual cluster management) |
| **Ansible** | 2.16.14 | dnf | Configuration management & automation |
| **ngrok** | 3.39.4 | binary | Expose local servers to the internet |
| **Caddy** | 2.11.3 | binary | Auto-HTTPS reverse proxy |
| **AWS CLI** | — | binary | Amazon Web Services CLI |

**How to use:**
```bash
# Terraform
terraform init
terraform plan
terraform apply

# Kubernetes
kubectl get pods
k9s              # visual cluster explorer

# Expose local dev server
ngrok http 3000  # gives you a public URL

# Caddy reverse proxy
caddy reverse-proxy --from example.com --to localhost:3000
```

---

## CLI Utilities

| Tool | Version | Install | Purpose |
|------|---------|---------|---------|
| **eza** | latest | cargo | Modern `ls` replacement (colors, icons, git status) |
| **hyperfine** | 1.20.0 | cargo | Command benchmarking tool |
| **duf** | 0.19.0 | cargo | Better `df` (disk usage) |
| **tldr** | 3.4.4 | pip | Simplified man pages with examples |
| **lazygit** | 0.61.1 | binary | Git TUI |
| **lazydocker** | 0.25.2 | binary | Docker TUI |
| **zoxide** | 0.9.9 | binary | Smart `cd` |
| **starship** | 1.25.1 | binary | Shell prompt |
| **zellij** | 0.44.3 | binary | Terminal multiplexer |
| **fzf** | — | dnf | Fuzzy finder |
| **ripgrep** | — | dnf | Ultra-fast grep |
| **fd-find** | — | dnf | Better find |
| **bat** | — | dnf | cat with syntax highlighting |
| **jq** | — | dnf | JSON processor |

**Aliases (in .bashrc):**
```bash
v     → nvim
lg    → lazygit
g     → git
gs    → git status
dc    → docker compose
ll    → ls -alF
```

---

## GUI Applications (Flatpak)

| App | Version | Purpose |
|-----|---------|---------|
| **VS Code** | 1.121.0 | Full IDE |
| **Obsidian** | 1.12.7 | Knowledge base |
| **Anki** | 25.09.04 | Flashcards |
| **DBeaver** | 26.0.5 | Database GUI |
| **Postman** | 12.12.2 | API testing |
| **Podman Desktop** | 1.27.2 | Container GUI |
| **draw.io** | 30.0.2 | Diagrams |
| **Logseq** | 0.10.15 | Graph notes |

---

## System Package Install (sudo required)

```bash
# 1. Add Docker repo (Rocky 10 uses RHEL repo)
sudo dnf config-manager --add-repo=https://download.docker.com/linux/rhel/docker-ce.repo

# 2. Docker + database clients + CLI tools
sudo dnf install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin \
    postgresql sqlite mariadb \
    htop bat fd-find ripgrep ShellCheck

# 3. Enable Docker and add user to docker group
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# 4. Redis (no RPM for Rocky 10 — run as container instead)
podman pull redis:latest
podman run -d --name redis -p 6379:6379 redis:latest
# Connect: redis-cli -h 127.0.0.1 (install via: pip install redis-cli)
```

### Rocky 10 Package Notes

| Package | Status | Notes |
|---------|--------|-------|
| `docker-ce` | Needs RHEL repo added first | Uses `docker.com/linux/rhel/` not `centos` |
| `redis` | **No RPM** on Rocky 10 | Run as Podman/Docker container instead |
| `fd-find` | Available in EPEL | Provides the `fd` command |
| `bat` | Available in EPEL | Provides the `bat` command |
| `ripgrep` | Available in EPEL | Provides the `rg` command |
