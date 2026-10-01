# erogeDOTS — Alpha 1.4

[Thai version](README.th.md)

Personal NixOS configuration for `moni`, built around Niri with GNOME kept as a fallback desktop. Kitty, Alacritty, Ghostty, Discord, Vesktop, Discordo, and the OpenCode CLI remain installed. The old custom Discord–OpenCode bridge is gone.

This repository is public so it is easy to clone onto my own machines. It is not a general-purpose NixOS distribution and it is not licensed for reuse.

## Cave mode

Clone at exact path. Run installer. Type sudo password once. Installer checks, builds, switches, restores theme. Done.

```bash
git clone <repository-url> /home/moni/erogeDOTS
cd /home/moni/erogeDOTS
./install.sh
```

Remember three keys: `Mod+Shift+/` shows the key guide, `Mod+T` opens themes, and `Mod+Ctrl+D` opens development shells.

## Normal guide

### Installation

Requirements: NixOS, user `moni`, the repository at `/home/moni/erogeDOTS`, and network access for the first build. `install.sh` performs the entire workflow:

1. Verifies the user, path, hostname, NixOS, and required commands.
2. Asks for sudo authentication once. NixOS cannot be safely activated without root authority.
3. Detects the hostname. For a new UEFI machine, it creates `hosts/<hostname>/hardware-configuration.nix` automatically.
4. Runs `nix flake check`, builds the exact host, then switches to it.
5. Restores the active theme and verifies the installed system and theme picker.
6. Saves the full log at `~/.local/state/erogedots/install.log`.

`NixChan` keeps its existing GRUB/EFI setup. Automatically created new hosts use systemd-boot. Review and commit a newly generated hardware file before relying on it elsewhere.

### Secrets

Never commit tokens, VPN keys, SSH private keys, Wi-Fi passwords, cookies, or `.env` files. Keep them outside this repository in a password manager, an encrypted secrets repository, or a host-local file with mode `0600`. Public dotfiles are fine; public credentials are not.

### Configuration shape

`configuration.nix` is the one shared system configuration. The old `nixos.nix` and per-host wrapper files were unnecessary, so they were merged. One small per-machine file still has to exist: `hosts/<hostname>/hardware-configuration.nix`. Disk UUIDs, filesystems, and device drivers are hardware facts and should not be mixed into the portable configuration.

Home Manager owns user applications, aliases, MIME defaults, and desktop files. A normal interactive Zsh terminal prints Fastfetch on startup; the animated mini terminal skips the duplicate Fastfetch screen. Theme sources live under `themes/`; `theme-switch` renders them into `~/.config`. Neovim now uses one bootstrap file and otherwise follows normal LazyVim defaults.

### Important Niri keys

`Mod` means the Super/Windows key.

| Key | Action |
| --- | --- |
| `Mod+Shift+/` | Show Niri's hotkey overlay |
| `Mod+Return` | Open Ghostty |
| `Mod+Shift+Return` | Open the small floating terminal |
| `Mod+grave` | Toggle dropdown terminal |
| `Mod+D` | Open application launcher |
| `Mod+T` | Open theme picker |
| `Mod+Shift+T` | Create a theme in the guided TUI |
| `Mod+Ctrl+D` | Choose a Nix development shell |
| `Mod+G` | Toggle the four-panel terminal wall |
| `Mod+Ctrl+V` | Open clipboard history |
| `Mod+Alt+R` | Open live memory monitor |
| `Mod+Alt+Z` | Toggle stay-awake/lid inhibitor |
| `Mod+S` | Toggle quick settings |
| `Mod+Shift+Space` | Cycle English, Japanese, and Thai input |
| `Super+Alt+L` | Lock screen |
| `Mod+O` | Toggle overview |
| `Mod+Q` | Close focused window |
| `Mod+Arrow` or `Mod+H/J/K/L` | Move focus |
| `Mod+Ctrl+Arrow` or `Mod+Ctrl+H/J/K/L` | Move a window |
| `Mod+1` … `Mod+9` | Focus workspace |
| `Mod+Ctrl+1` … `Mod+Ctrl+9` | Move window to workspace |
| `Mod+V` | Toggle floating |
| `Mod+W` | Toggle tabbed column |
| `Mod+F` / `Mod+Shift+F` | Maximize column / fullscreen window |
| `Print` / `Ctrl+Print` / `Alt+Print` | Region / screen / window screenshot |
| `Mod+Shift+W` | Open session menu |

### Everyday scripts and short commands

Every script has a keyboard route. Long names also get a short shell alias; already-short commands stay unchanged.

| Script | What it does | Hotkey | Short command |
| --- | --- | --- | --- |
| `theme-switch` | Renders and applies desktop themes | `Mod+T` | `ts`, `tspick`, `tsadd`, `tslist`, `tscurrent`, `tspreview` |
| `cliphist-pick` | Picks clipboard history through Fuzzel | `Mod+Ctrl+V` | `clip` |
| `dropterm` | Toggles the dropdown Ghostty window | `Mod+grave` | `drop` |
| `fcitx5-cycle.sh` | Cycles configured input methods | `Mod+Shift+Space` | `ime` |
| `larp` | Toggles the four terminal panels | `Mod+G` | `larp` |
| `ram` | Shows, watches, or trims memory-heavy apps | `Mod+Alt+R` | `ram` |
| `unzzz` | Starts, stops, or toggles lid-close inhibition | `Mod+Alt+Z` | `unzzz` |

### Themes

Use `Mod+T` or `ts` to choose an existing theme. The picker shows each theme's wallpaper beside the list, using the terminal's image protocol when available and a colored half-block preview as fallback. Use `Mod+Shift+T` or `tsadd` to create one. The Rust TUI asks for the theme ID and character details, then shows a live image preview while browsing `wallpapers/`, `~/Pictures`, and `~/Downloads`. Choose one of six color schemes with visible swatches and exact hex values. The next screen shows every editable theme color, including Niri and Bottom: press `Enter` on a color to choose a swatch, use `Tab` to select R/G/B (or shadow alpha), `←/→` to change it by 1, `[`/`]` by 16, and `s` to continue. The TUI copies the image and writes a complete `theme.conf`. Fetch and Cmatrix support named colors only, so their color follows the nearest named color to the chosen primary accent.

Manual commands remain available:

```bash
theme-switch list
theme-switch current
theme-switch preview harumi
theme-switch harumi
```

To add a palette manually, copy any complete `themes/<name>/theme.conf` and its wallpaper, keep the lowercase ID safe (`a-z`, `0-9`, `-`), then run `theme-switch <name>`. The generated TUI route is preferred because it fills every required template value.

### Development shells

Run `dev` or press `Mod+Ctrl+D`. The TUI offers `default`, `rust`, `python`, `go`, `java`, `common`, `tester`, `docker`, `security`, `webapp`, and `pg-computer`, then starts the selected `nix develop` shell. Direct use still works: `nix develop .#rust` (`nix develop .#java` for JDK 21 + Maven + Gradle + IntelliJ IDEA).

## Every tracked file

The list is intentionally explicit. If a file is not here, it should not be part of the public configuration.

### Repository and Nix

- `.gitattributes` — normalizes Git text handling.
- `.gitignore` — excludes build output, local state, secrets, and generated files.
- `README.md` — this complete English guide.
- `README.th.md` — the complete Thai guide.
- `flake.nix` — entry point; discovers hosts, builds packages, wires Home Manager, and exports dev shells.
- `flake.lock` — pins every flake input for repeatable builds.
- `configuration.nix` — shared NixOS system, boot choice, services, desktops, input methods, fonts, and security defaults.
- `home/moni.nix` — user packages, aliases, applications, MIME defaults, and theme restoration.
- `hosts/NixChan/hardware-configuration.nix` — generated hardware facts for NixChan only.
- `install.sh` — unattended validation, host discovery, build, activation, theme restore, and final checks.
- `shells.nix` — definitions for all selectable development environments.

### Editor and local packages

- `config/nvim/init.lua` — minimal Lazy.nvim bootstrap that loads stock LazyVim.
- `picker-rs/Cargo.toml` — Rust TUI package metadata and direct dependencies.
- `picker-rs/Cargo.lock` — exact Rust dependency versions.
- `picker-rs/src/main.rs` — theme picker, guided theme creator, dev-shell picker, and unit tests.
- `pkgs/chatgpt/default.nix` — wraps the upstream ChatGPT desktop AppImage as a Nix package.

### Scripts

- `scripts/theme-switch` — validates theme values, renders templates, installs configs, stores state, and reloads the desktop.
- `scripts/cliphist-pick` — clipboard history selector.
- `scripts/dropterm` — dropdown terminal controller.
- `scripts/fcitx5-cycle.sh` — input-method cycler.
- `scripts/larp` — four-panel terminal wall controller.
- `scripts/ram` — memory report/watch/cleanup helper; OpenCode remains a normal CLI process.
- `scripts/unzzz` — temporary systemd lid-close inhibitor with start, stop, and toggle modes.

### Theme data

- `themes/harumi/theme.conf` — Harumi palette and character metadata.
- `themes/nanami/theme.conf` — Nanami palette and character metadata.
- `themes/natsume/theme.conf` — Natsume palette and character metadata.
- `themes/nene/theme.conf` — Nene palette and character metadata.
- `themes/sana/theme.conf` — Sana palette and character metadata.
- `wallpapers/harumi.jpg` — Harumi wallpaper.
- `wallpapers/nanami.jpg` — Nanami wallpaper.
- `wallpapers/natsume.jpg` — Natsume wallpaper.
- `wallpapers/nene.jpg` — Nene wallpaper.
- `wallpapers/sana.jpg` — Sana wallpaper.

### Generated-config templates

- `themes/templates/alacritty/alacritty.toml` — Alacritty colors and opacity.
- `themes/templates/cava/config` — Cava visualizer colors.
- `themes/templates/cmatrix/config` — Cmatrix color setting.
- `themes/templates/fetch/config` — terminal system-info colors.
- `themes/templates/fuzzel/fuzzel.ini` — application-launcher appearance.
- `themes/templates/ghostty/config` — Ghostty colors and opacity.
- `themes/templates/kitty/kitty.conf` — Kitty colors and opacity.
- `themes/templates/niri/config.kdl` — Niri layout, window rules, startup commands, and all hotkeys.
- `themes/templates/quickshell/` — romance VN shell: `shell.qml` assembles the chapter bar and illustrated settings menu; `Theme.qml` supplies the palette, `ShellState.qml` owns hardware state, and `NiriState.qml` follows compositor events.
- `themes/templates/wlogout/` — matching session menu.
- `themes/templates/swaync/config.json` — notification-center behavior.
- `themes/templates/swaync/style.css` — notification-center colors and styling.

## Romance VN desktop

The shell uses cream panels, pastel character accents, serif nameplates and small floral frames. `Mod+S` opens the system menu; `Mod+D` opens the launcher; `Mod+Shift+W` opens session choices. Escape or clicking outside closes the system menu. Buttons and sliders support keyboard focus. Bluetooth controls are unavailable when the system has no enabled adapter.

The five themes share `vn_paper`, `vn_ink`, and `vn_muted`, with individual `vn_accent`, `vn_tint`, and `vn_line` colors. Older themes and themes made by the picker inherit the rose interface defaults; add those six keys to customize them. Terminal backgrounds remain dark at 92% opacity. Existing terminal windows may need reopening.

Run `theme-switch <name>` to apply changes. It renders every flat file in the template folders, including QML components and `qmldir`, and safely restarts only this desktop shell. Edit source templates in this repository, not generated files under `~/.config`.

Validation (requires Python 3.11+, Niri, Fuzzel and Quickshell):

```sh
python3 tests/theme-render.py
bash tests/check-niri-state.sh
cargo test --locked --manifest-path picker-rs/Cargo.toml
```

## Ownership and reuse

Copyright © 2026 moni. All rights reserved.

There is deliberately no MIT license. The repository is visible for personal synchronization and reference, but public visibility does not grant permission to copy, redistribute, publish, sublicense, or sell the contents. Dependencies and upstream software keep their own licenses.
