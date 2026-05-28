# Wofi — Task Board

## Done
- [x] Diagnose rofi Wayland failure (layer-shell protocol unsupported in mainline rofi)
- [x] Evaluate rofi-wayland fork vs wofi; chose wofi (Wayland-first, lighter)
- [x] Confirm neither wofi nor gtk-layer-shell is packaged for Rocky 10
- [x] Write `install-wofi.sh` (builds gtk-layer-shell + wofi from source, temp-dir clones)
- [x] Write `setup-wofi-keybind.sh` (Super+Space via gsettings)
- [x] Write `uninstall-wofi.sh`
- [x] Add `config` + Catppuccin Mocha `style.css`
- [x] Write README, setup guide, logs
- [x] Organize as a self-contained feature dir (now at `chezmoi/private_dot_config/wofi/`)

## Done (audit + staging + chezmoi fix, 2026-05-27)
- [x] Audited machine state (see logs/setup-log.md + docs/finish-on-this-machine.md)
- [x] Staged `~/.config/wofi/{config,style.css}` via cp
- [x] Fixed keybind script to repoint existing Super+Space slot (was dead rofi binding)
- [x] Fixed chezmoi root: `.chezmoiroot=chezmoi`, moved remote-desktop/rofi/wofi under `chezmoi/private_dot_config/`
- [x] Single source of truth: `~/.config/chezmoi/chezmoi.toml` sourceDir → `~/coding/Dotfiles`
- [x] Verified `chezmoi managed` maps cleanly (no `$HOME` junk); committed + pushed

## In Progress
- [ ] Run `install-wofi.sh` on the Rocky 10 host (needs sudo — user runs) then verify `wofi --show drun`

## Next Up
- [ ] Decide the 3 diverged configs (mise/starship/zellij): `chezmoi add` vs `chezmoi apply` (see finish doc)
- [ ] Decide whether to retire the X11 rofi scripts + clone (don't delete without asking)
- [ ] Optionally remove the orphaned `~/.local/share/chezmoi` clone

## Future
- [ ] Pin wofi/gtk-layer-shell to specific tags for reproducible builds
- [ ] Add extra modes (window switcher, clipboard, power menu) with their own styles
- [ ] Share the Catppuccin style upstream / across other GTK launchers
