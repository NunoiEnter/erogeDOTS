# ⚠️ erogeDOTS — VER.1.1.b

> **⚠️ WARNING: MY PERSONAL DOTFILES — NOT FOR YOU ⚠️**
>
> This is **my** personal NixOS setup. Runs on **my** machine (`NixChan`), uses **my**
> themes, **my** keybinds, **my** little quirks. This isn't a template or a distro —
> it's just my home.
>
> **STATUS: STILL BUILDING.** I break things, fix them, and move on. Don't expect
> stability. Don't expect support. If you copy this and something explodes —
> that's on you, not me. ⚠️

---

## 🎮 What even is this

My NixOS dotfiles with a visual-novel look (waifu themes), one theme-switcher that
re-colors everything, and a lightweight desktop stack on **niri**.

Why "lightweight"? I tried Noctalia (a whole desktop shell). It looked amazing but
ate resources. So I dropped it and rebuilt the same look with small tools: waybar,
swaync, fuzzel — way lighter, still pretty.

## 🧱 Where stuff lives

```
erogeDOTS/
├── flake.nix                  # the inputs (nixpkgs, home-manager, qylock, zen)
├── install.sh                 # fresh-machine installer
├── hosts/NixChan/             # my machine: system config + hardware
├── home/modules/              # my home-manager stuff
│   ├── desktop.nix            # waybar, mimeapps, zen, figma
│   └── terminal.nix           # terminal tools + my aliases
├── themes/                    # theme definitions
│   ├── sana/ harumi/ nanami/ natsume/ nene/   # theme.conf each
│   └── templates/             # app configs with {{color}} placeholders
│       ├── niri/  waybar/  swaync/  fuzzel/
│       ├── ghostty/ alacritty/ foot/ kitty/
│       └── catnap/ cava/ cmatrix/
├── scripts/
│   ├── theme-switch           # the magic: theme → configs → switch
│   └── tspick                 # theme picker launcher (uses theme-picker)
├── picker-rs/                 # my Rust theme picker (compiled once)
├── pkgs/catnap/               # catnap package override
├── config/                    # static configs (nvim, openvpn, zen, ...)
├── modules/nixos/             # shared nixos modules
├── shells/                    # dev shells (rust, python, go, docker, ...)
├── wallpapers/                # theme wallpapers
└── docs/                      # my notes (dev, install, vpn)
```

## 🥞 My stacks

### Desktop shell (lightweight — no Qt6 bloat)

| Piece | What it does for me |
|---|---|
| **niri** | my tiling compositor — scrollable columns, tabbed, overview |
| **waybar** | Noctalia-style bar — full width, capsule widgets, launcher/notif/clipboard/session |
| **swaync** | my notifications |
| **fuzzel** | launcher + dmenu |
| **wlogout** | session menu (power off, reboot, logout) |
| **qylock** | my lock screen (patched so mouse clicks work) — swaylock as backup |
| **wlsunset** | night light, manual toggle (`Mod+Ctrl+W`) |
| **cliphist** | clipboard history (`Mod+Ctrl+V`) |
| **grim + slurp + swappy** | screenshots + region annotate (`Print` family) |

### Theming

- **theme-switch** — one command, re-colors 11 apps: niri, waybar, swaync, fuzzel,
  ghostty, alacritty, foot, kitty, catnap, cava, cmatrix
- **picker-rs** — my Rust picker with live wallpaper previews
- Themes: `sana`, `harumi`, `nanami`, `natsume`, `nene`

### Keybinds I actually use

| Key | Action |
|---|---|
| `Mod+Return` | terminal (ghostty) |
| `Mod+D` | app launcher (fuzzel) |
| `Mod+Ctrl+V` | clipboard history |
| `Mod+Shift+W` | session menu (wlogout) |
| `Mod+Ctrl+W` | night light toggle |
| `Super+Alt+L` | lock (qylock) |
| `Print` / `Ctrl+Print` / `Alt+Print` / `Shift+Print` | screenshot / screen / window / annotate |
| `Mod+Shift+/` | hotkey overlay (all binds listed) |
| `Mod+O` | overview |

Full list: press `Mod+Shift+/` anytime.

## 🚀 Installing (if you're me)

### Fresh machine

```bash
bash <(curl -s https://raw.githubusercontent.com/NunoiEnter/erogeDOTS/main/install.sh)
```

That clones the repo, runs `sudo nixos-rebuild switch --flake .#NixChan`, then
compiles the Rust theme-picker once into `~/.local/bin/theme-picker`.

### Already cloned — just rebuild

```bash
cd ~/erogeDOTS
sudo nixos-rebuild switch --flake .#NixChan
```

### Theme/config tweaks (no rebuild needed)

```bash
theme-switch sana          # or: harumi nanami natsume nene
niri msg action load-config-file
pkill waybar; waybar &
```

## ⚠️ Read this before you copy me

- Hostname is **`NixChan`** — hardware-configuration is for MY hardware only.
- My aliases, my colors, my keybinds. Yours will (and should) differ.
- `allowUnfree` overlap deliberately left alone.
- **Still building.** Expect churn.

## 📚 My notes

- `docs/DEVELOPMENT.md`, `docs/INSTALL.md`
- `docs/larper.md`, `docs/vpn-instructions.md`

---

**VER.1.1.b** — personal, WIP, waifu-powered. えへへ 💕
