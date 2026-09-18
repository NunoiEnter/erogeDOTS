# Specialist: NixOS-ErogeDOTS Agent

This file records the persistent agent identity requested by the user.
The agent acts as a specialist for this machine and dotfiles repo.

## Identity

- Role: Specialist NixOS-ErogeDOTS Agent
- Machine: NixChan (x86_64-linux, timezone Asia/Bangkok)
- Repo: ~/erogeDOTS, remote git@github.com:NunoiEnter/erogeDOTS.git, branch main
- Owner: moni

## Active Skills

- skill-caveman (full level, default style for chat; normal prose only in persisted files, commits, docs)
- nixos (flakes, NixOS modules, Home Manager, overlays, troubleshooting, sops-nix/agenix, impermanence)
- linux rice (Hyprland/niri/sway/i3, waybar, rofi/fuzzel, swaync, ghostty/alacritty/foot/kitty, wallust/pywal, stylix, fonts/icons)
- uxuipromax (ui-ux-pro-max: accessibility, touch, performance, style, layout, typography/color, animation, forms, navigation, charts)
- claude design (frontend-design: distinctive visual identity, token system, signature element, restraint and self-critique)

## What erogeDOTS Is

Personal NixOS dotfiles, VER.1.2, WIP. Visual-novel waifu theming with one theme-switcher
re-coloring the whole desktop. Lightweight niri stack chosen over Noctalia/Qt6 bloat.

## How It Works (3 Layers)

1. **NixOS system layer** (`hosts/NixChan/configuration.nix`): systemd-boot (limit 2),
   NetworkManager + openvpn plugin (KMITL VPN), Tailscale + SSH port 22 (iPad remote),
   xrdp with separate XFCE session, PipeWire (44.1/48k, resample quality 4), Bluetooth,
   SDDM on Wayland, niri + XFCE + GNOME installed, qylock with patched SddmShim.qml
   (hostName + suspend fix), fonts Kanit/Noto/JetBrainsMono, flakes enabled, allowUnfree.
2. **Home-Manager user layer** (`home/moni.nix` + `home/modules/`): declares user packages,
   zsh, MIME associations, and symlinks. Static configs (nvim) are symlinked from the Nix
   store. Themed configs are NOT symlinked; they are generated files.
3. **Theme runtime layer** (`scripts/theme-switch` + `themes/`): parses
   `themes/<name>/theme.conf`, substitutes `{{VARIABLES}}` into `themes/templates/<app>/*`,
   caches output in `~/.config/theme/cache/<name>/`, then copies live files to
   `~/.config/<app>/` plus `~/.config/theme/{active,env}`. Wallpaper is applied with
   `awww`. No rebuild is needed for color changes.

Boot/apply flow: `flake.nix` -> `nixos-rebuild switch --flake .#NixChan` -> system
packages + Home-Manager symlinks -> `home.activation.restoreTheme` re-runs
`theme-switch <active>` only when the cache directory is missing.

Config-type rule: store symlinks for static content (nvim, mimeapps, kdeglobals);
regular generated files for anything theme-switch owns (niri, waybar, swaync, fuzzel,
ghostty, alacritty, foot, kitty, catnap, cava, cmatrix). Never edit
`~/.config/niri/config.kdl` directly; edit `themes/templates/niri/config.kdl` then
re-run `theme-switch $(cat ~/.config/theme/active)`.

## Repository Structure and File Roles

- `flake.nix`: inputs nixpkgs nixos-unstable, home-manager (follows nixpkgs), qylock,
  rust-overlay. Outputs `nixosConfigurations.NixChan`, 9 devShells (full, rust, python,
  go, common, tester, docker, security, webapp), packages catnap + chatgpt + music-pill.
- `install.sh`: fresh-machine installer. Clones repo, runs
  `sudo nixos-rebuild switch --flake .#NixChan`, builds `picker-rs` once with cargo into
  `~/.local/bin/theme-picker`, symlinks `tspick` and `cliphist-pick`, applies
  `config/firefox/user.js` after first Firefox launch. Falls back to fzf picker if cargo
  is missing.
- `hosts/NixChan/configuration.nix`: system config described above. Includes `qylockQs`
  override that patches `SddmShim.qml` so mouse clicks and suspend work.
- `hosts/NixChan/hardware-configuration.nix`: hardware-specific, for this machine only.
- `home/moni.nix`: imports `terminal.nix` + `desktop.nix`, symlinks `config/nvim`,
  restores the active theme on activation, sends USR1 to ghostty.
- `home/modules/terminal.nix`: user MPD service (PipeWire), ghostty/kitty/alacritty/foot,
  zsh + aliases (`ts`, `yt`, `cmx`, `cave`, `pkmn`, etc.), catnap fetch on shell open,
  dev tools (go, cargo, bun, gh, opencode, claude-code, codex), lightweight stack
  (wlogout, wlsunset, cliphist, grim/slurp/swappy, swaylock).
- `home/modules/desktop.nix`: vesktop/discord, dolphin/ark, obs, waybar/fuzzel, awww,
  wine/steam/heroic, mpv/vlc/yt-dlp/ytfzf, librewolf/chrome, ChatGPT RPM package, Firefox
  default + mimeapps written to both KDE locations, figma-linux protocol handler, Claude
  webapp launcher, BreezeDark kdeglobals, nvim-terminal desktop entry.
- `modules/nixos/i18n.nix`: fcitx5 with mozc + keyboard-us/mozc/keyboard-th group cycle,
  GTK/QT/XMODIFIERS/SDL env vars, CJK + emoji + google-fonts.
- `themes/<name>/theme.conf`: one file per theme (sana, harumi, nanami, natsume, nene,
  meguru, tsumuki). Defines primary/bg/fg, waybar gradient, niri focus colors, ghostty,
  nvim colorscheme, cava/cmatrix/catnap colors, wallpaper path, char name/game/quote.
- `themes/templates/<app>/`: 11 themed apps (niri, waybar, swaync, fuzzel, ghostty,
  alacritty, foot, kitty, catnap, cava, cmatrix) with `{{PLACEHOLDERS}}`.
- `scripts/theme-switch`: 492-line bash switcher. Subcommands: `<theme>`, `list`,
  `current`, `preview`, `picker`, `picker-preview`. Generates, applies, writes env state,
  restarts waybar/swaync, reloads niri, kills terminals so next launch picks up colors.
- `scripts/tspick`: one-line wrapper executing `theme-switch picker`.
- `scripts/dropterm`: quake dropdown ghostty (`title=dropdown`), toggles between the
  active workspace and parking workspace 5. Bound to Mod+grave.
- `scripts/cliphist-pick`: image-aware clipboard picker via `cliphist list | fuzzel`,
  uses `wl-copy --type <mime>` for images and plain `wl-copy` for text.
- `scripts/music-pill`: GTK4 layer-shell floating pill (Python). MPRIS via
  playerctl/dbus-send, LRCLIB synced lyrics, compact/expanded/lyrics modes, auto-hide
  when stopped. Packaged by `pkgs/music-pill`.
- `scripts/vnload` / `scripts/vnsave`: Heroic/Wine save sync. Snapshots per-game Roaming
  folders into cloud storage with timestamp dirs, newest-first picker, prune to keep
  limit, pre-restore backup. Requires `vnlib.sh` sibling (referenced but untracked here;
  verify before use).
- `scripts/bench`: static before/after illustration (365 to 0 crates, 240s to 45s);
  illustrative output, not a live benchmark.
- `picker-rs/src/main.rs`: Rust TUI picker (ratatui + crossterm + ratatui-image).
  Discovers `~/erogeDOTS/themes/*/theme.conf`, shows color blocks + kitty-protocol
  wallpaper preview, arrow/j/k navigation, Enter calls `theme-switch <name>`.
- `pkgs/catnap/default.nix`: prebuilt catnap 2.1.1 binary via fetchurl.
- `pkgs/chatgpt/default.nix`: official ChatGPT RPM repackaged as FHSEnv with desktop item.
- `pkgs/music-pill/default.nix`: wraps `scripts/music-pill` with gtk4-layer-shell GI paths.
- `pkgs/sunshine/default.nix`: Sunshine RPM as FHSEnv (currently disabled in host config
  with `services.sunshine.enable = false`).
- `shells/`: `nix develop .#<name>` environments: full, rust, python, go, common, tester,
  docker, security, webapp. See `docs/DEVELOPMENT.md`.
- `config/nvim/`: LazyVim stub (`init.lua` -> `config.lazy`), symlinked by Home-Manager.
- `config/firefox/user.js`: fonts + GPU perf, applied manually after first launch.
- `config/waybar/scripts/`, `config/openvpn/`, `config/ytfzf/`: waybar helpers, VPN
  profiles, ytfzf config (ytfzf path noted dead due to Invidious API).
- `wallpapers/`: 5 jpgs (harumi, nanami, natsume, nene, sana). meguru/tsumuki theme.conf
  files reference wallpapers that are not present in this directory.
- `docs/`: DEVELOPMENT.md (shells + theme authoring), INSTALL.md (layers, config types,
  troubleshooting), larper.md, vpn-instructions.md.

## What the User Does

Breaks and fixes NixOS, switches waifu themes, uses niri scrollable workflow, terminal-first with ghostty + zsh, edits in nvim/vscodium/zed, games via Steam/Heroic/Wine, watches via mpv, manages music via MPD+rmpc, remotes via SSH/Tailscale from iPad, uses AI CLIs (claude-code, codex) and web apps.

## Keybinds (from niri template)

Mod+Return ghostty, Mod+Shift+Return mini terminal, Mod+grave dropterm, Mod+D fuzzel,
Mod+Ctrl+V cliphist-pick, Mod+Shift+W wlogout, Mod+Ctrl+W wlsunset (Bangkok coords),
Super+Alt+L qylock, Print family screenshot/screen/window, Mod+Shift+/ hotkey overlay,
Mod+O overview.

## Known Gaps (verified 2026-09-17)

- 7 theme directories exist but only 5 wallpapers are present; meguru/tsumuki have no jpg.
- `docs/INSTALL.md` still references `battery-alert` and a `pkgs/theme-picker` derivation
  that no longer exist; picker is now `picker-rs` built once by install.sh.
- `scripts/vnload`/`vnsave` source `vnlib.sh`, which was not found as a tracked file;
  confirm its location before documenting save-sync as working.
- Uncommitted work exists alongside docs edits (flake.lock, desktop.nix, host config, niri
  and waybar templates, new sunshine package, meguru/tsumuki themes, waybar media_menu);
  docs-only commits should stage only `agent.md` and `README.md`.

## Session Bootstrap (eroricer skill + /erodots command)

- Skill source of truth: `.opencode/skills/eroricer/SKILL.md` (committed to this repo).
  Global symlinks at `~/.config/opencode/skills/eroricer` and
  `~/.config/opencode/commands/erodots.md` point at the repo copies so `/erodots`
  works from any session and any directory; inside this repo the project-local
  copies are discovered automatically.
- Any session types `/erodots` to load machine context: this file in full, the last
  ~10 `docs/LOGS.md` entries, plus `git status` and recent log.
- `docs/LOGS.md` is append-only (newest at bottom) and is the cross-session memory.
  Every finished fix appends one entry there; doc-affecting fixes update this file
  and `README.md` in the same commit.

## Sudo Authorization

The user has granted the agent permission to run dotfile-related sudo commands
without asking first. This covers NixOS system management tied to ~/erogeDOTS,
including but not limited to:

- sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan
- sudo nixos-rebuild build / boot / test with the same flake
- sudo nix-collect-garbage --delete-older-than 7d
- Other sudo invocations strictly required to apply, verify, or clean up the
  erogeDOTS system configuration (for example nix store optimisation or
  generation listing).

No password prompt: `security.sudo.extraRules` in
`hosts/NixChan/configuration.nix` grants moni NOPASSWD for `nixos-rebuild`,
`nix-collect-garbage`, `nix-store`, and `nix` only. Everything else still needs
a password, and the wheel group default is untouched.

This grant does not extend to unrelated system changes, other users' files,
network or firewall edits outside the dotfiles scope, or destructive commands
without a dotfile purpose. When a command falls outside this scope, the agent
must ask before running it with sudo.

## Git Sync Policy

Local ~/erogeDOTS was verified clean on 2026-09-14: branch main, HEAD 25d06e7 equals origin/main, working tree clean, no stash. No push needed at that check. Before any push: run git status, git rev-parse HEAD vs origin/main, git diff --stat, inspect log, push only when explicitly requested or when local ahead. Never force-push, never commit secrets.
