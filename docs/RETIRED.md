# Retired — backed up before deletion

This file records everything removed during the 2026-09-27 cleanup so it can
be restored. Nothing here is needed for a working desktop. Each entry says
where it lived, why it went, and how to bring it back.

## 1. scripts/bench (static illustration, not a live benchmark)

- Lived: `scripts/bench` + zsh alias `bench` (old `home/modules/terminal.nix`)
- Why: hardcoded bars (`365 to 0 crates`, `240s to 45s`). Never measured the
  local machine. Misleading name.
- Restore: `git show HEAD~1:scripts/bench > scripts/bench && chmod +x scripts/bench`
  History kept in git.

## 2. scripts/vnload + scripts/vnsave (dangling symlinks)

- Lived: `scripts/vnload -> /home/moni/Heroic-Saves/bin/vnload`,
  `scripts/vnsave -> /home/moni/Heroic-Saves/bin/vnsave`
- Why: targets live outside the repo (`~/Heroic-Saves`, untracked). Fresh clone
  gets broken symlinks. Scripts also need sibling `vnlib.sh` plus env vars
  (`VNCLOUD`, `PREFIXES_DIR`, `KEEP_SNAPS`) that were never committed.
- Restore: if `~/Heroic-Saves/bin/vnload` exists, relink:
  `ln -sf ~/Heroic-Saves/bin/vnload scripts/vnload`
  `ln -sf ~/Heroic-Saves/bin/vnsave scripts/vnsave`
  Full logic lives outside git by design (save data stays out of dotfiles).

## 3. config/ytfzf + ytfzf package

- Lived: `config/ytfzf/config.sh`, `ytfzf` in home packages
- Why: `config.sh` itself says Invidious search API blocked. Aliases use
  `yt-dlp`/`mpv` directly. Config was 2 comment lines.
- Restore: `ytfzf` still in nixpkgs. Re-add package + drop a fresh config in
  `config/ytfzf/` if upstream recovers.

## 4. config/openvpn/ placeholder

- Lived: `config/openvpn/README.md` (6 lines)
- Why: real `*.ovpn` files are gitignored by design. Folder held only a readme.
  Instructions already live in `docs/vpn-instructions.md`.
- Restore: `mkdir -p config/openvpn`, drop `.ovpn` files there. They stay local,
  never committed (`*.ovpn` in `.gitignore`).

## 5. services.sunshine.enable = false toggle

- Lived: one line in system config
- Why: no sunshine package in repo (`pkgs/sunshine/` deleted earlier). A false
  toggle with no package is dead config.
- Restore: re-add package under `pkgs/sunshine/` + `services.sunshine.enable = true`
  in `hosts/NixChan/modules/remote.nix`.

## 6. Waybar + Eww leftovers

- Lived: staged deletions `themes/templates/waybar/*`, `config/waybar/*`,
  migration shims in `theme-switch` (`rm -rf ~/.config/eww ~/.config/waybar`,
  `pkill .eww-wrapped`)
- Why: desktop is quickshell-only since 2026-09-26 (Senren Banka bar + popover).
  Shims kept one release for migration, then removed.
- Restore: `git log --all --oneline -- themes/templates/waybar/` then
  `git show <hash>:<path>` for any file.

## 7. waybar_* theme keys (renamed to bar_*)

- Lived: `waybar_bg_gradient`, `waybar_border`, `waybar_shadow`, `waybar_text`,
  `waybar_active_bg`, `waybar_workspace_active`, `waybar_workspace_default`,
  `waybar_clock_icon` in every `themes/*/theme.conf`
- Why: waybar gone. Only `waybar_border` still consumed (by quickshell).
  Renamed to `bar_*` so names match reality. `theme-switch` accepts old
  `waybar_*` as fallback for one release, then the fallback goes.
- Restore: old key names in git history. New names documented in
  `themes/SCHEMA.md`.

## 8. picker-rs/target/ build output
- Lived: `picker-rs/target/` (local only, gitignored)
- Why: compiled binary output. Source is `picker-rs/src/main.rs`. Binary ships
  to `~/.local/bin/theme-picker` via `install.sh`.
- Restore: `cd picker-rs && cargo build --release`

## 9. blueman / bluez user packages
- Lived: `blueman`, `bluez`, `bluez-tools` in home packages
- Why: system Bluetooth is off (`hosts/NixChan/modules/bluetooth.nix`, RAM goal).
  User-space tools with no radio are dead weight. System module owns Bluetooth;
  flip it to `true` and rebuild when a headset is needed.
- Restore: set `hardware.bluetooth.enable = true` + `services.blueman.enable = true`
  in `hosts/NixChan/modules/bluetooth.nix`, rebuild, re-add tools if wanted.
