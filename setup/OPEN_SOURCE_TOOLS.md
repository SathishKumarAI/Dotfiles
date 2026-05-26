# Open-Source Dev Environment Tools — Comparison & Recommendations

Researched 2026-05-26. Focused on tools that work on Rocky Linux / RHEL.

---

## TL;DR — Recommended Stack for Rocky Linux

| Layer | Tool | Stars | Why |
|-------|------|-------|-----|
| Language versions | **mise** | 28.6k | Single binary, manages Node/Python/Go/Ruby/Java. Faster than asdf |
| Dotfiles | **chezmoi** | 19.9k | Templates, encryption, multi-machine support. Gold standard |
| Package management | **Nix + home-manager** | 9.8k | Declarative, reproducible, works alongside dnf without root |
| Per-project envs | **Devbox** | 11.6k | Isolated dev shells via Nix, no Nix knowledge needed |
| Machine provisioning | **Ansible** | — | Best for initial system setup (dnf, services, firewall) |

---

## 1. Dotfiles Managers

| Tool | Stars | Description | Rocky Support |
|------|-------|-------------|---------------|
| [chezmoi](https://github.com/twpayne/chezmoi) | 19.9k | Manage dotfiles across machines. Templating, encryption, cross-platform. | Yes (Go binary) |
| [dotbot](https://github.com/anishathalye/dotbot) | 7.9k | Lightweight bootstrapper using YAML config for symlinks + shell commands. | Yes (Python) |
| [YADM](https://github.com/yadm-dev/yadm) | 6.3k | Thin Git wrapper with alt-file support, encryption, bootstrapping. | Yes (shell script) |
| [GNU Stow](https://github.com/aspiers/stow) | 1.0k | Symlink farm manager. Simple: organize dirs, stow creates links. | Yes (in EPEL) |
| [Dotter](https://github.com/SuperCuber/dotter) | 2.0k | Dotfile manager + templater in Rust. | Yes (single binary) |
| [Mackup](https://github.com/lra/mackup) | 15.2k | Backup/sync app settings. | Partial (macOS-focused) |

### Verdict: **chezmoi** is the clear winner for multi-machine setups. It handles templating (e.g., different configs per hostname), secret encryption via age/gpg, and auto-applying on new machines.

---

## 2. Language/Tool Version Managers

| Tool | Stars | Description | Rocky Support |
|------|-------|-------------|---------------|
| [mise](https://github.com/jdx/mise) (formerly rtx) | 28.6k | Dev tools + env vars + task runner. Manages Node, Python, Go, Ruby, Java, and 500+ tools. | Yes (single binary) |
| [asdf](https://github.com/asdf-vm/asdf) | 25.4k | Plugin-based version manager for 500+ tools. | Yes (shell-based) |

### Verdict: **mise** has surpassed asdf in both features and performance. It's also a task runner and env var manager (replaces direnv). Already included in the custom script.

---

## 3. Nix Ecosystem

| Tool | Stars | Description | Rocky Support |
|------|-------|-------------|---------------|
| [home-manager](https://github.com/nix-community/home-manager) | 9.8k | Declarative user environment management via Nix. Reproducible, rollback-capable. | Yes (Nix on any Linux) |
| [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) | 3.6k | Best way to install Nix. 7M+ installs, better UX than official installer. | Yes |
| [Devbox](https://github.com/jetify-com/devbox) | 11.6k | Instant isolated dev environments. `devbox.json` per project. Nix under the hood, no Nix knowledge needed. | Yes |

### Verdict: **Devbox** is the easiest entry point. If you want full declarative control, graduate to **home-manager**. Install Nix via Determinate installer.

---

## 4. Opinionated Workstation Setups

| Tool | Stars | Description | Rocky Support |
|------|-------|-------------|---------------|
| [Omakub](https://github.com/basecamp/omakub) | 8.1k | DHH's one-command Ubuntu setup (Alacritty, Zellij, Neovim, Docker, etc.) | **No** (Ubuntu only) |
| [thoughtbot/laptop](https://github.com/thoughtbot/laptop) | 8.6k | macOS web/mobile dev setup. | **No** (macOS only) |
| [donnemartin/dev-setup](https://github.com/donnemartin/dev-setup) | 6.3k | macOS dev env with Vim, Python, AWS. | **No** (macOS only) |
| [mac-dev-playbook](https://github.com/geerlingguy/mac-dev-playbook) | 7.0k | Jeff Geerling's Ansible playbook for macOS. Great pattern to adapt. | **No** (but best Ansible pattern to copy) |

### Verdict: No Rocky/RHEL equivalent exists with high stars. **Omakub** is worth studying for inspiration. An "Omakub for Rocky" is a gap you could fill.

---

## 5. Ansible Workstation Playbooks (Linux)

| Tool | Stars | Description | Rocky Support |
|------|-------|-------------|---------------|
| [LearnLinuxTV/personal_ansible_desktop_configs](https://github.com/LearnLinuxTV/personal_ansible_desktop_configs) | 341 | Jay LaCroix's multi-distro Ansible configs. Good learning resource. | Partial |
| [rothgar/ansible-workstation](https://github.com/rothgar/ansible-workstation) | 26 | Ansible playbook for Fedora desktop. | Yes (adaptable) |

### Verdict: No dominant "Rocky dev playbook" exists. Build your own using `ansible.builtin.dnf` — Geerling's mac playbook is the best structural template.

---

## How These Tools Fit Together

```
┌─────────────────────────────────────────────────┐
│              Fresh Rocky Linux Machine            │
├─────────────────────────────────────────────────┤
│                                                   │
│  1. ANSIBLE (or bash script)                      │
│     └─ System packages (dnf), services,           │
│        firewall, Docker, users                    │
│                                                   │
│  2. CHEZMOI                                       │
│     └─ Pull dotfiles from GitHub                  │
│        (shell config, nvim, tmux, git, etc.)      │
│                                                   │
│  3. MISE                                          │
│     └─ Install language runtimes                  │
│        (Node LTS, Python 3.12, Go 1.24)          │
│                                                   │
│  4. DEVBOX (optional, per-project)                │
│     └─ Isolated project environments              │
│        (devbox.json in each repo)                 │
│                                                   │
│  5. NIX + HOME-MANAGER (advanced, optional)       │
│     └─ Declarative everything                     │
│        (replaces steps 2-4 if you go all-in)      │
│                                                   │
└─────────────────────────────────────────────────┘
```

---

## Quick Install Commands

### chezmoi (dotfiles)
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply SathishKumarAI
```

### mise (language versions)
```bash
curl https://mise.run | sh
mise use --global node@lts python@3.12 go@latest
```

### Devbox (project environments)
```bash
curl -fsSL https://get.jetify.com/devbox | bash
cd your-project && devbox init && devbox add python@3.12 nodejs@22
devbox shell  # isolated environment
```

### Nix + home-manager (declarative everything)
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

### Ansible (machine provisioning)
```bash
dnf install -y ansible-core
ansible-pull -U https://github.com/SathishKumarAI/rocky-dev-setup.git playbook.yml
```
