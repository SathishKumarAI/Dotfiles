# Docs archive

Superseded documents, kept whole. **Nothing here is canonical.** Every file was
merged into a live doc; this folder exists so the original wording, tables and
numbers stay recoverable without digging through git history.

Do not link to these from live docs, and do not update them — fix the canonical
doc instead. Where a topic lives is answered by
[`../LIBRARY-INDEX.md`](../LIBRARY-INDEX.md).

## `md-files/` — retired 2026-08-01

Was `docs/md files/`. The space in that folder name is what produced every
`%20` link in the tree. Content merged as follows:

| Archived file | Merged into | What carried over |
|---|---|---|
| `KEYBOARD-SHORTCUTS.md` (420 ln) | [`../terminal/KEYBOARD-SHORTCUTS.md`](../terminal/KEYBOARD-SHORTCUTS.md) | GNOME extensions (7 subsections), Nautilus, TLP, zsh, Wayland/XWayland quirks, frequency-tier memorisation order |
| `zoxide.md` (269 ln) | [`../shell/zoxide.mdx`](../shell/zoxide.mdx) | scoring model, per-OS install table, shell-init section |
| `path_fix.md` (303 ln) | [`../setup/windows.mdx`](../setup/windows.mdx) | the `setx PATH` root cause and the do/don't rules. Its inline script is superseded by `setup/update-user-path.ps1` |
| `SYSTEM-TUNING.md` (95 ln) | [`../guides/RAM-AND-PERFORMANCE.md`](../guides/RAM-AND-PERFORMANCE.md) | boot-unit and disk-cleanup notes — the **Arch laptop's** numbers, 2026-06-05 |

What did *not* carry over was duplication: sections the canonical docs already
covered, and in `path_fix.md` a full inline PowerShell script that the repo now
ships as a maintained file.

## `vault-tools/` — archived 2026-08-01

Obsidian notes that restated the automation docs. The vault keeps its index and
templates; these two summaries did not earn a second copy.

| Archived file | Canonical doc |
|---|---|
| `mise.md` | [`../automation/mise.mdx`](../automation/mise.mdx) |
| `chezmoi.md` | [`../automation/chezmoi.mdx`](../automation/chezmoi.mdx) |

Their `[[mise]]` / `[[chezmoi]]` wikilinks in `../vault/tools/Tool Index.md` no
longer resolve inside the vault — that index now points at the canonical docs.
