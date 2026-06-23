# Contributing

This is a personal dotfiles repo, but fixes, ports, and ideas are welcome.

## Reporting bugs / requests

Open a [GitHub issue](https://github.com/SathishKumarAI/Dotfiles/issues) with:

- Your OS + version (e.g. Rocky Linux 10.1, Arch, Windows 11)
- The exact command you ran
- The full output / error

## Pull requests

1. Branch off `main` (`feat/…`, `fix/…`, `docs/…`).
2. Keep changes **additive** — extend configs; don't rebind or delete existing
   keys/settings someone may rely on. This is a hard rule for `chezmoi/` configs.
3. Anything needing `sudo` goes in `setup/` as a standalone `.sh` script (don't
   inline long privileged commands).
4. Make sure CI passes before pushing:
   ```bash
   find . -name '*.sh' -not -path './.git/*' -exec bash -n {} \;          # syntax
   find . -name '*.sh' -not -path './.git/*' -exec shellcheck -S warning {} +
   wezterm --config-file chezmoi/dot_wezterm.lua ls-fonts >/dev/null      # config valid
   ```
5. Update docs alongside code. Docs follow the house style in
   [`docs/templates/README.md`](docs/templates/README.md): lead with the point,
   tables over prose, show the *why*.

## Commit style

[Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`,
`docs:`, `chore:`, `refactor:`. Keep the subject ≤ ~50 chars; add a body only
when the *why* isn't obvious from the subject.

## Repo layout

- `chezmoi/` — config layer (source → `$HOME`)
- `setup/` — package layer + provisioning scripts
- `docs/` — documentation (see [`docs/setup/architecture.mdx`](docs/setup/architecture.mdx) for the provisioning model)

Thanks for contributing.
