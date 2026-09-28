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

Themes: `harumi` (pink), `nanami` (purple), `natsume` (warm), `nene` (lavender),
`sana` (red). `meguru`/`tsumuki` parked in `themes/incomplete/` (no wallpaper yet).

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
│   niri, quickshell, ghostty, fuzzel, swaync, catnap, fetch │
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
| `~/.config/quickshell/` | Regular files | Generated per-theme |
| `~/.config/ghostty/` | Regular files | Generated per-theme |
| `~/.config/fuzzel/` | Regular files | Generated per-theme |
| `~/.config/swaync/` | Regular files | Generated per-theme |
| `~/.config/catnap/` | Regular files | Generated per-theme |
| `~/.config/fetch/` | Regular files | Generated per-theme |

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
3. Add app name to `apps` array in `scripts/theme-switch` (both arrays)
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
├── flake.nix                    # Flake: nixpkgs, home-manager, qylock, rust-overlay
├── flake.lock                   # Locked inputs
├── install.sh                   # One-command installer
├── hosts/NixChan/
│   ├── configuration.nix        # Thin router, imports modules/
│   ├── hardware-configuration.nix
│   └── modules/                 # boot/network/desktop/audio/power/fonts/i18n/gaming/bluetooth/remote/nix-settings/users
├── home/
│   ├── moni.nix                 # 9 home modules, nvim symlink, theme restore hook
│   └── modules/
│       ├── shell.nix            # Terminals, zsh, core aliases
│       ├── dev.nix              # Dev tools + AI CLIs
│       ├── fun.nix              # Terminal toys
│       ├── desktop.nix          # Session tools
│       ├── apps.nix             # Daily apps
│       ├── gaming.nix           # wine/steam/heroic
│       ├── media.nix            # MPD + rmpc
│       ├── mime.nix             # Mimeapps + launchers
│       └── discord-opencode.nix # Bridge service
├── themes/
│   ├── SCHEMA.md                # Key contract
│   ├── templates/               # Config templates with {{VARIABLES}}
│   │   ├── niri/config.kdl
│   │   ├── quickshell/shell.qml
│   │   ├── ghostty/config
│   │   ├── fuzzel/fuzzel.ini
│   │   ├── swaync/{config.json,style.css}
│   │   ├── alacritty/alacritty.toml
│   │   ├── foot/foot.ini
│   │   ├── kitty/kitty.conf
│   │   ├── catnap/
│   │   ├── fetch/config
│   │   ├── cava/config
│   │   └── cmatrix/config
│   ├── sana/harumi/nanami/natsume/nene/  # 5 live themes
│   └── incomplete/              # meguru, tsumuki (no wallpaper yet)
├── scripts/
│   ├── theme-switch             # Theme switcher (bash)
│   ├── lib/common.sh            # APPS list + autodetect (edit here)
│   ├── tspick/dropterm/cliphist-pick/fcitx5-cycle.sh
│   ├── ram/unzzz/zzz
│   └── mk-boot-partition        # LIVE-USB ONLY
├── pkgs/
│   ├── catnap/default.nix       # Catnap fetchurl (prebuilt binary, default shell fetch)
│   ├── chatgpt/                 # Official RPM as FHSEnv
│   └── discord-opencode/        # Rust bridge (areofyl fetch comes from nixpkgs)
├── picker-rs/                   # Rust picker source
├── shells/                      # Dev shells (rust, python, go, common, full, tester, docker, security, webapp, pg-computer)
├── config/
│   ├── nvim/                    # Base nvim config (symlinked by home-manager)
│   └── firefox/user.js          # Fonts + GPU perf
├── wallpapers/                  # 5 live wallpapers
└── docs/
    ├── INSTALL.md               # This file
    ├── DEVELOPMENT.md           # Dev shells & theme creation
    └── RETIRED.md               # Removed things + restore
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

Home-manager handles this via `xdg.configFile` and `xdg.dataFile` in `home/modules/mime.nix`.

### xwayland not working

`xwayland-satellite` auto-creates X11 socket. Check it's running:

```bash
pgrep -x xwayland-satellite
```

If not, it spawns on demand when an X11 app launches.
