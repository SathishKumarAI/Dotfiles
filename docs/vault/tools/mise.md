# mise

> Obsidian note. Canonical doc: [`mise.mdx`](../../automation/mise.mdx) —
> update that first; this is the vault-side summary.

**What:** Single tool that manages all language runtimes.
**Replaces:** pyenv, nvm, goenv, sdkman, rustup
**Config:** `~/.config/mise/config.toml`

## Why We Use It
One config file defines all tool versions. When you `cd` into a project with a `.mise.toml`, versions auto-switch. No more "which Python am I using?" confusion.

## Current Config
```toml
[tools]
python = "3.12"
node = "lts"
go = "latest"
```

## Common Commands
```bash
mise ls                      # show installed versions
mise use python@3.11         # set version for current dir
mise use --global rust@latest # add a new global tool
mise install                 # install from config
mise upgrade                 # update all tools
mise ls-remote python        # see available versions
mise doctor                  # check for issues
```

## Per-Project Config
Drop `.mise.toml` in any project:
```toml
[tools]
python = "3.11"
node = "22"
```

#tools #mise #versions
