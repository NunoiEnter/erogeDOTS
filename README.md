# erogeDOTS — ALPHA 1.4

Personal NixOS fleet for `moni`. Niri is the main desktop; GNOME and XFCE stay
available. Kitty, Alacritty, Ghostty, and Foot are all kept.

This repository is public. It contains configuration and wallpapers, never live
credentials.

## Install

On an already installed NixOS machine using the `moni` account:

```bash
git clone https://github.com/NunoiEnter/erogeDOTS.git ~/erogeDOTS
cd ~/erogeDOTS
./install.sh
```

The installer detects the hostname, creates a host from `hosts/_template` when
needed, generates hardware configuration, checks the flake, builds, switches,
applies the current theme, and verifies the result. It asks no configuration
questions. NixOS may ask once for the sudo password. Full output is saved at
`~/.local/state/erogedots/install.log`.

`NixChan` keeps its special GRUB layout. New hosts default to UEFI systemd-boot.
Automatic creation intentionally refuses BIOS-only machines.

## Everyday commands

```bash
sudo nixos-rebuild switch --flake path:$HOME/erogeDOTS#NixChan
theme-switch list
theme-switch harumi
theme-switch picker
nix develop                         # full development shell
nix develop .#rust                  # named shell
```

Rollback after a bad activation:

```bash
sudo nixos-rebuild switch --rollback
```

## Secrets

Keep these outside the repository:

- Discord tokens: `~/.config/opencode/discord-bot.env` (`0600`)
- SSH private keys: `~/.ssh/`
- Wi-Fi passwords: NetworkManager connection store
- VPN profiles and keys: import them into NetworkManager from private storage
- Any `.env`, `*.ovpn`, `*.key`, `*.pem`, `*.p12`, or `*.pfx`

Only the blank Discord example is tracked. `.gitignore` blocks common secret
files, but ignore rules cannot remove a secret from old Git history. Rotate any
credential that was ever committed before publishing.

## Layout: what each file does

Core:

| File | Purpose |
|---|---|
| `flake.nix` | Pins inputs, discovers hosts, exports packages and dev shells. |
| `flake.lock` | Exact dependency revisions for repeatable builds. |
| `nixos.nix` | Shared NixOS system: users, Nix, network, SSH, desktop, audio, power, locale, fonts, Steam. |
| `home/moni.nix` | All Home Manager packages, GNOME-adjacent desktop apps, Kitty/Alacritty/Ghostty/Foot, shell, MIME defaults, Firefox, Discord service. |
| `install.sh` | Unattended host detection, generation, check, build, switch, theme, verification. |
| `shells.nix` | All named development environments in one file. |
| `.gitignore` | Keeps builds, local OpenCode state, and secret file types out of Git. |
| `.gitattributes` | GitHub language/display hints. |
| `LICENSE` | MIT terms for repository code. |

Hosts and editor:

| File | Purpose |
|---|---|
| `hosts/NixChan/configuration.nix` | NixChan hostname and its GRUB/EFI choices. |
| `hosts/NixChan/hardware-configuration.nix` | NixChan disks and detected hardware. |
| `hosts/_template/configuration.nix` | Safe UEFI default copied for a new hostname. |
| `config/nvim/init.lua` | Neovim entrypoint. |
| `config/nvim/lua/config/*.lua` | Autocommands, keys, plugin loader, and options. |
| `config/nvim/lua/plugins/init.lua` | Neovim plugin declarations. |

Packages:

| File | Purpose |
|---|---|
| `picker-rs/Cargo.toml` / `Cargo.lock` | Rust picker manifest and locked dependencies. |
| `picker-rs/src/main.rs` | Interactive terminal theme picker. |
| `picker-rs/default.nix` | Reproducible Nix build for the picker. |
| `pkgs/chatgpt/default.nix` | Nix wrapper for the official ChatGPT Linux package. |
| `pkgs/discord-opencode/Cargo.toml` / `Cargo.lock` | Discord bridge manifest and dependency lock. |
| `pkgs/discord-opencode/default.nix` | Nix build for the Discord bridge. |
| `pkgs/discord-opencode/discord-bot.env.example` | Blank, safe credential template. |
| `pkgs/discord-opencode/src/*.rs` | Bridge config, Discord/OpenCode adapters, permissions, projects, repository, settings, and tasks. |

Scripts:

| File | Purpose |
|---|---|
| `scripts/theme-switch` | Validates a theme, renders templates, applies configs, wallpaper, and reloads apps. |
| `scripts/cliphist-pick` | Clipboard history picker. |
| `scripts/dropterm` | Toggleable drop-down Ghostty terminal. |
| `scripts/fcitx5-cycle.sh` | Cycle English, Japanese, and Thai input. |
| `scripts/larp` | Opens or closes the four-pane terminal wall. |
| `scripts/ram` | Shows memory use and optionally stops safe user processes. |
| `scripts/unzzz` | Starts/stops a user-level lid/sleep inhibitor. |

Themes:

| File | Purpose |
|---|---|
| `themes/SCHEMA.md` | Supported theme keys and template rules. |
| `themes/{harumi,nanami,natsume,nene,sana}/theme.conf` | Complete color, wallpaper, and character metadata. |
| `themes/incomplete/{meguru,tsumuki}/theme.conf` | Parked themes whose wallpapers are missing; pickers ignore them. |
| `themes/templates/<app>/*` | Source templates for Niri, Quickshell, terminals, Fuzzel, SwayNC, Fetch, Cava, and CMatrix. |
| `wallpapers/*.jpg` | Wallpaper assets for complete themes. |

## Add another machine

Use the same three install commands. If its hostname is new, `install.sh` creates
`hosts/<hostname>/configuration.nix` and `hardware-configuration.nix`. Review and
commit those two machine-specific files afterward. Shared changes belong in
`nixos.nix`; personal applications belong in `home/moni.nix`.

## License

Code is MIT licensed. Wallpapers and upstream package assets keep their original
rights and are not relicensed by this repository.
