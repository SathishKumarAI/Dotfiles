# Backlog — Dotfiles / Terminal Environment

Future work for the WezTerm · Neovim · Zellij · chezmoi stack. The block below is
read by the local Khanban board (`~/coding/khanban-for-me`) as Backlog cards.
See the visual board at [`docs/terminal/backlog.html`](terminal/backlog.html).

<!-- khanban:start -->
- [ ] Restore chezmoi apply — remove stray empty dot_config dir
- [ ] Track ~/.wezterm.lua in chezmoi so it deploys reproducibly
- [ ] End-to-end test the resurrect save/restore flow
- [ ] Prevent accidental window close with a confirmation prompt
- [ ] Auto-generate the cheatsheet from wezterm show-keys
- [ ] Add Neovim LSP + completion (Mason, lspconfig, blink.cmp)
- [ ] Add Neovim treesitter syntax highlighting
- [ ] Add auto-format on save with conform.nvim
- [ ] Add a CI gate (shellcheck, bash -n, wezterm show-keys) on PRs
- [ ] Expand Zellij layouts with a per-project ML workspace
- [ ] Theme lazygit and delta with Catppuccin Mocha
- [ ] Build a single-source pipeline for cheatsheet, markdown, and HTML shortcuts
<!-- khanban:end -->
