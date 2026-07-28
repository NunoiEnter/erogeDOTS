# erogeDOTS Installation Guide

One-command setup for fresh NixOS devices.

## Prerequisites

- Fresh NixOS 26.05 installation (or reinstall)
- Internet connection
- User in `wheel` group with sudo access

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/NunoiEnter/erogeDOTS/main/install.sh | bash
```

Or clone manually:

```bash
git clone https://github.com/NunoiEnter/erogeDOTS.git ~/erogeDOTS
cd ~/erogeDOTS
./install.sh
```

## What It Does

1. Clones repo to `~/erogeDOTS`
2. Runs `sudo nixos-rebuild switch --flake .#NixChan`
3. Home-manager activates, installs all packages
4. `restoreTheme` hook runs `theme-switch <active>` to generate configs

## After Install

### Pick a Theme

```bash
theme-picker              # interactive Rust picker (arrow keys + preview)
theme-switch list         # or list themes
theme-switch nanami       # switch directly
```

Themes: `harumi` (pink), `nanami` (purple), `natsume` (warm), `nene` (lavender)

### Flatpak Apps

EarX (Nothing earbuds ANC) needs manual install:

```bash
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.somaxa8.earx
```

### First Reboot

```bash
sudo reboot
```

SDDM loads. Session dropdown (top-left) for XFCE/GNOME. Niri is default.

## Architecture

### Config Layers

```
┌─────────────────────────────────────────────────┐
│ NixOS system (configuration.nix)                │
│   niri, XFCE, GNOME, SDDM, pipewire, bluetooth │
├─────────────────────────────────────────────────┤
│ Home-manager (home/moni.nix + modules/)         │
│   packages, zsh, aliases, mimeapps, nvim        │
│   → symlinks to nix store                       │
├─────────────────────────────────────────────────┤
│ Theme-switch (scripts/theme-switch)             │
│   niri, waybar, ghostty, fuzzel, swaync, catnap │
│   → generated from templates, copied to ~/.config│
└─────────────────────────────────────────────────┘
```

### Config Types

| Location | Method | Why |
|----------|--------|-----|
| `~/.config/nvim` | Symlink → nix store | Static, version-pinned |
| `~/.config/mimeapps.list` | Symlink → nix store | Static MIME associations |
| `~/.config/kdeglobals` | Symlink → nix store | KDE dark theme |
| `~/.config/niri/` | Regular files | Generated per-theme |
| `~/.config/waybar/` | Regular files | Generated per-theme |
| `~/.config/ghostty/` | Regular files | Generated per-theme |
| `~/.config/fuzzel/` | Regular files | Generated per-theme |
| `~/.config/swaync/` | Regular files | Generated per-theme |
| `~/.config/catnap/` | Regular files | Generated per-theme |

### Theme System Flow

```
themes/<name>/theme.conf          ← color definitions
        ↓
themes/templates/<app>/           ← config templates with {{VARIABLES}}
        ↓
theme-switch <name>               ← sed substitution
        ↓
~/.config/theme/cache/<name>/    ← generated configs (cached)
        ↓
cp -r → ~/.config/<app>/         ← live configs (regular files, not symlinks)
```

**Why not symlinks?** Templates need variable substitution. The generated file changes per theme — can't symlink to a path that changes.

### Adding a New App to Theme-Switch

1. Create template: `themes/templates/myapp/config`
2. Add `{{VARIABLES}}` from `theme.conf`
3. Add app name to `apps` array in `scripts/theme-switch` (lines 159, 180)
4. Run `theme-switch <current-theme>` to regenerate

### Editing Niri Config

**Don't edit `~/.config/niri/config.kdl` directly** — it gets overwritten on theme switch.

Edit the template instead:

```bash
$EDITOR ~/erogeDOTS/themes/templates/niri/config.kdl
theme-switch $(cat ~/.config/theme/active)
```

Or edit `theme.conf` for color changes:

```bash
$EDITOR ~/erogeDOTS/themes/nanami/theme.conf
theme-switch nanami
```

## File Structure

```
erogeDOTS/
├── flake.nix                    # Flake: nixpkgs, home-manager, zen-browser
├── flake.lock                   # Locked inputs
├── install.sh                   # One-command installer
├── hosts/NixChan/
│   ├── configuration.nix        # NixOS system config
│   └── hardware-configuration.nix
├── home/
│   ├── moni.nix                 # Home-manager user config
│   └── modules/
│       ├── terminal.nix         # Packages, zsh, aliases
│       └── desktop.nix          # Packages, mimeapps, kdeglobals
├── themes/
│   ├── templates/               # Config templates with {{VARIABLES}}
│   │   ├── niri/config.kdl
│   │   ├── waybar/{config.jsonc,style.css}
│   │   ├── ghostty/config
│   │   ├── fuzzel/config.ini
│   │   ├── swaync/{config.json,style.css}
│   │   ├── alacritty/alacritty.toml
│   │   ├── foot/foot.ini
│   │   └── kitty/kitty.conf
│   ├── nanami/theme.conf        # Theme color definitions
│   ├── harumi/theme.conf
│   ├── natsume/theme.conf
│   └── nene/theme.conf
├── scripts/
│   ├── theme-switch             # Theme switcher (bash)
│   └── battery-alert            # Battery monitor
├── pkgs/
│   ├── theme-picker/default.nix # Rust TUI picker (Nix derivation)
│   └── catnap/default.nix       # Catnap fetchurl (prebuilt binary)
├── picker-rs/                   # Rust picker source
├── shells/                      # Dev shells (rust, python, go, etc.)
├── config/
│   ├── nvim/                    # Base nvim config (symlinked by home-manager)
│   ├── waybar/scripts/          # Waybar helper scripts
│   ├── fuzzel/                  # Base fuzzel config
│   └── ytfzf/                   # ytfzf config (dead — Invidious API blocked)
├── wallpapers/                  # Theme wallpapers
├── modules/nixos/               # NixOS modules (i18n)
└── docs/
    ├── INSTALL.md               # This file
    └── DEVELOPMENT.md           # Dev shells & theme creation
```

## Troubleshooting

### niri validate fails

Check template for syntax errors:

```bash
niri validate 2>&1 | head -20
```

Common issue: KDL syntax changes between niri versions. Check [niri wiki](https://github.com/niri-wm/niri/wiki/Configuration:-Window-Rules).

### Theme not applying

```bash
theme-switch $(cat ~/.config/theme/active)
```

Forces regeneration from current theme's templates.

### Boot partition full

```bash
sudo nix-collect-garbage -d
sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan
```

### MIME associations broken (Dolphin opens wrong app)

KDE ignores `xdg.mimeApps` wildcards (`image/*`). Must use explicit MIME types and write to BOTH locations:

- `~/.config/mimeapps.list`
- `~/.local/share/applications/mimeapps.list`

Home-manager handles this via `xdg.configFile` and `xdg.dataFile` in `desktop.nix`.

### xwayland not working

`xwayland-satellite` auto-creates X11 socket. Check it's running:

```bash
pgrep -x xwayland-satellite
```

If not, it spawns on demand when an X11 app launches.
