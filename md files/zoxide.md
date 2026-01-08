# zoxide + dotfiles — Technical Documentation

## Overview

**zoxide** is a fast directory navigation utility designed as a smarter replacement for `cd`.
It maintains a weighted database of visited directories and resolves jumps using **recency-frequency heuristics**.

When integrated into **dotfiles**, zoxide becomes a portable, deterministic navigation layer across environments.

---

## Architecture Summary

**Components**

* CLI binary (`zoxide`)
* Shell hook (bash / zsh / fish / PowerShell)
* Local database (`~/.local/share/zoxide/db.zo`)

**Data Model**

* Path → score
* Score = f(frequency, recency)

No filesystem crawling, no background indexing.

---

## Supported Platforms & Shells

| OS      | Shells          |
| ------- | --------------- |
| Linux   | bash, zsh, fish |
| macOS   | bash, zsh, fish |
| Windows | PowerShell      |

---

## Installation

### macOS

```bash
brew install zoxide
```

### Debian / Ubuntu

```bash
sudo apt install zoxide
```

### Arch Linux

```bash
sudo pacman -S zoxide
```

### Windows (PowerShell)

```powershell
winget install zoxide
```

Verify:

```bash
zoxide --version
```

---

## Shell Initialization (Dotfiles)

zoxide **requires shell initialization** to intercept directory changes.

### Bash (`~/.bashrc`)

```bash
eval "$(zoxide init bash)"
```

### Zsh (`~/.zshrc`)

```bash
eval "$(zoxide init zsh)"
```

### Fish (`~/.config/fish/config.fish`)

```fish
zoxide init fish | source
```

Commit these files into your dotfiles repository.

---

## Recommended Dotfiles Layout

```text
dotfiles/
├── bash/
│   └── bashrc
├── zsh/
│   └── zshrc
├── fish/
│   └── config.fish
├── install.sh
└── README.md
```

Each shell loads zoxide deterministically on setup.

---

## Core Commands

### Jump to directory

```bash
z project
```

### List matches

```bash
z -l project
```

### Interactive selection

```bash
z -i
```

### Jump to previous directory

```bash
z -
```

---

## Alias Strategy (Optional)

Replace `cd` globally:

```bash
alias cd="z"
```

This preserves muscle memory while enabling zoxide scoring.

---

## Integration with fzf (Optional)

If `fzf` is installed, zoxide automatically enables interactive fuzzy selection.

No configuration required.

---

## Scoring Algorithm (Conceptual)

For each directory:

* Increment score on `chdir`
* Apply decay over time
* Rank results by weighted score

This ensures:

* Frequently used paths dominate
* Recently used paths override stale ones

---

## Database Location

```text
~/.local/share/zoxide/db.zo
```

* Portable
* Lightweight
* Can be backed up or synced if needed

---

## Behavior on New Machines

Workflow:

1. Clone dotfiles
2. Install zoxide
3. Open shell

Result:

* Same navigation behavior
* Same commands
* Zero re-learning

---

## Best Practices

* Keep zoxide initialization minimal
* Avoid manual aliases for directories
* Let scoring adapt naturally
* Pair with dotfiles, not ad-hoc installs

---

## Summary

zoxide is not a shortcut tool — it is a **behavior-learning navigation layer**.
Dotfiles turn it into a **portable system primitive**.

Minimal setup. Deterministic behavior. Compounding gains.

---

## References & Official Docs

1. **zoxide – Official GitHub Repository**
   [https://github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide)
   *Source code, README, installation methods, shell init examples, and design notes.*

2. **zoxide Documentation (README)**
   [https://github.com/ajeetdsouza/zoxide#readme](https://github.com/ajeetdsouza/zoxide#readme)
   *Primary reference for commands, flags, scoring behavior, and integrations.*

3. **fzf – Command-line Fuzzy Finder**
   [https://github.com/junegunn/fzf](https://github.com/junegunn/fzf)
   *Optional integration used by zoxide for interactive directory selection.*

4. **Dotfiles Best Practices (GitHub Docs)**
   [https://dotfiles.github.io/](https://dotfiles.github.io/)
   *Community-driven guidelines for structuring and managing dotfiles.*

5. **GNU Bash Startup Files**
   [https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html](https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html)
   *Reference for `.bashrc` loading and shell initialization behavior.*

6. **Zsh Startup Files**
   [https://zsh.sourceforge.io/Doc/Release/Files.html](https://zsh.sourceforge.io/Doc/Release/Files.html)
   *Explains `.zshrc`, `.zprofile`, and execution order.*

7. **Fish Shell Configuration**
   [https://fishshell.com/docs/current/index.html](https://fishshell.com/docs/current/index.html)
   *Official fish shell config and initialization documentation.*

---

## Optional Reading (Deep Dive)

* **Why “z” tools outperform aliases**
  [https://github.com/rupa/z](https://github.com/rupa/z)
  *Historical context for frequency-based directory jumping.*

* **CLI UX Design Principles**
  [https://clig.dev/](https://clig.dev/)
  *Design philosophy behind ergonomic CLI tools like zoxide.*

---

