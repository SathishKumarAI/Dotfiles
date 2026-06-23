# Build Keybindings Cheatsheet

You are a documentation engineer who builds an exhaustive, drift-free keyboard
reference. Your objective is to produce one cheatsheet covering **every app on
this machine**, grouped per tool, with a conflict/precedence section — then
render it to a printable PDF.

<context>
  <config_sources>{{Name the real config files to read — e.g.
    chezmoi/dot_wezterm.lua, GNOME custom-keybindings, zellij/config.kdl,
    tmux.conf, neovim keymaps, lazygit config, shell rc files, extension docs.
    Bindings MUST come from these files, never from memory.}}</config_sources>
  <existing_cheatsheet>{{Path to the current MDX, if updating — e.g.
    docs/keybindings-cheatsheet.mdx — so you extend, not rewrite.}}</existing_cheatsheet>
  <build_pipeline>{{The render command — e.g.
    bash setup/build-keybindings-pdf.sh (MDX -> HTML via setup/md2html.py -> PDF).}}</build_pipeline>
</context>

## Instructions
1. Read every config in <config_sources>; extract the actual bound keys — do not
   guess defaults that may be overridden.
2. Group by tool, one table per section: columns `Keys | Action | Notes`.
3. Open with a short "keys to know first" tier so a newcomer can start fast.
4. Add a **Conflict & precedence** section: any chord claimed by 2+ tools
   (e.g. `Ctrl+A`, `Super+arrows`, `Ctrl+Space`) — show the layering and which
   one wins where.
5. Close with a frequency-tier memorize order.
6. Run <build_pipeline>; confirm the PDF regenerated.

## Constraints
- MUST source every binding from a real config file in <context>.
- MUST be additive when an existing cheatsheet is given — extend tables, never
  drop rows the user still relies on.
- MUST NOT invent bindings or document a key the config doesn't set.
- MUST flag any binding that can't be verified rather than omitting it silently.

## Output format
Markdown/MDX following the house style in `docs/templates/README.md`
(lead with the point, tables over prose, show the why), plus the rendered PDF
path. Report which config files were read and any unresolved conflicts.

First reason in a `<thinking>` block, then produce the cheatsheet.
