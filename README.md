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

## Layout: what each file does / แต่ละไฟล์เอาไว้ทำอะไร

### Core / ส่วนหลักของระบบ

| File / ไฟล์ | English | ภาษาไทย |
|---|---|---|
| `flake.nix` | Main project entrypoint. Defines dependency sources, available hosts, packages, and development shells. | จุดเริ่มต้นของโปรเจกต์ บอก Nix ว่าใช้แหล่งแพ็กเกจอะไร มีเครื่องไหน และสร้างโปรแกรมหรือชุดเครื่องมืออะไรได้บ้าง |
| `flake.lock` | Locks every dependency to an exact revision so builds stay reproducible across machines. | ล็อกเวอร์ชันของทุก dependency เพื่อให้ติดตั้งใหม่หรือย้ายเครื่องแล้วได้ผลเหมือนเดิม |
| `nixos.nix` | Shared system configuration for users, networking, SSH, desktops, audio, power, locale, fonts, and Steam. | ตั้งค่าระบบที่ใช้ร่วมกันทุกเครื่อง เช่น ผู้ใช้ เครือข่าย SSH เดสก์ท็อป เสียง พลังงาน ภาษา ฟอนต์ และ Steam |
| `home/moni.nix` | Home Manager configuration for applications, terminals, Zsh, Firefox, default apps, and the Discord bot service. | ตั้งค่าส่วนของผู้ใช้ `moni` เช่น โปรแกรม Kitty, Alacritty, Ghostty, Foot, Zsh, Firefox แอปเริ่มต้น และ Discord bot service |
| `install.sh` | Detects the host and hardware, checks and builds the configuration, activates it, applies the theme, and verifies the result. | ตัวติดตั้งอัตโนมัติ ตรวจชื่อเครื่องและ hardware จากนั้นตรวจ config, build, เปิดใช้ระบบใหม่ ใส่ธีม และเช็กผลลัพธ์ |
| `shells.nix` | Contains development environments for Rust, Python, Go, Web, Docker, testing, security, and other tasks. | รวมชุดเครื่องมือสำหรับงานพัฒนา เช่น Rust, Python, Go, Web, Docker, Testing และ Security |
| `.gitignore` | Prevents build output, local state, caches, and common secret file types from entering Git. | กันไฟล์ build, สถานะเฉพาะเครื่อง, cache และไฟล์ที่อาจมี secret ไม่ให้ถูกอัปโหลดขึ้น Git |
| `.gitattributes` | Gives GitHub hints for file display and language statistics. | ช่วยให้ GitHub แสดงชนิดไฟล์และสถิติภาษาใน repo ได้เหมาะสม |

### Hosts and Neovim / เครื่องแต่ละตัวและ Neovim

| File / ไฟล์ | English | ภาษาไทย |
|---|---|---|
| `hosts/NixChan/configuration.nix` | NixChan-specific hostname and GRUB/EFI boot settings. | ค่าเฉพาะเครื่อง NixChan เช่นชื่อเครื่องและวิธีบูตด้วย GRUB/EFI |
| `hosts/NixChan/hardware-configuration.nix` | Hardware, disk, filesystem, and CPU settings detected for NixChan. | ข้อมูล hardware, ดิสก์, พาร์ทิชัน และ CPU ของ NixChan ที่ NixOS ตรวจพบ |
| `hosts/_template/configuration.nix` | Safe UEFI and systemd-boot defaults used when adding a new host. | แม่แบบสำหรับเพิ่มเครื่องใหม่ โดยเริ่มจากค่า UEFI และ systemd-boot ที่ปลอดภัย |
| `config/nvim/init.lua` | First file loaded by Neovim; it connects the rest of the editor configuration. | ไฟล์แรกที่ Neovim โหลด แล้วส่งต่อไปยัง config ส่วนอื่น |
| `config/nvim/lua/config/*.lua` | Neovim keybindings, options, automatic behavior, and plugin loader. | เก็บปุ่มลัด ตัวเลือก พฤติกรรมอัตโนมัติ และระบบโหลด plugin ของ Neovim |
| `config/nvim/lua/plugins/init.lua` | Declares and configures Neovim plugins. | รายชื่อและการตั้งค่า plugin ที่ Neovim ต้องใช้ |

### Local packages / โปรแกรมที่สร้างเองใน repo

| File / ไฟล์ | English | ภาษาไทย |
|---|---|---|
| `picker-rs/Cargo.toml` / `Cargo.lock` | Lists the Rust libraries and exact versions used by the theme picker. | รายชื่อ library และเวอร์ชันที่ใช้สร้างโปรแกรมเลือกธีม |
| `picker-rs/src/main.rs` | Interactive terminal theme picker with color and wallpaper previews. | โปรแกรมเลือกธีมใน terminal พร้อมดูสีและ wallpaper ก่อนเลือก |
| `picker-rs/default.nix` | Tells Nix how to build and install the theme picker. | บอก Nix ว่าต้อง build และติดตั้ง theme picker อย่างไร |
| `pkgs/chatgpt/default.nix` | Packages the ChatGPT Linux application for NixOS. | แพ็ก ChatGPT Linux ให้ติดตั้งและเปิดผ่าน NixOS ได้ |
| `pkgs/discord-opencode/Cargo.toml` / `Cargo.lock` | Lists the Rust libraries and versions used by the Discord–OpenCode bridge. | รายชื่อ library และเวอร์ชันของ Discord–OpenCode bridge |
| `pkgs/discord-opencode/default.nix` | Tells Nix how to build the Discord–OpenCode bridge. | บอก Nix ให้ build Discord–OpenCode bridge อย่างไร |
| `pkgs/discord-opencode/discord-bot.env.example` | Blank example showing which environment variables the bot needs; it contains no real token. | ตัวอย่างชื่อค่าที่ bot ต้องใช้ เป็นไฟล์ว่างและไม่มี token จริง |
| `pkgs/discord-opencode/src/*.rs` | Bot code split by responsibility: Discord, OpenCode, permissions, projects, settings, and tasks. | โค้ดของ bot แยกตามหน้าที่ เช่น Discord, OpenCode, permission, project, settings และ task |

### Scripts / สคริปต์ที่ใช้ประจำ

| File / ไฟล์ | English | ภาษาไทย |
|---|---|---|
| `scripts/theme-switch` | Reads a theme, generates application configs, changes the wallpaper, and reloads affected apps. | อ่านค่าธีม สร้าง config ของแต่ละแอป เปลี่ยน wallpaper และ reload แอปที่เกี่ยวข้อง |
| `scripts/cliphist-pick` | Searches clipboard history and restores the selected item. | เปิดรายการ clipboard เก่าให้ค้นหาและเลือกนำกลับมาใช้ |
| `scripts/dropterm` | Opens or hides a drop-down Ghostty terminal. | เปิดหรือซ่อน Ghostty แบบ terminal เลื่อนลงจากด้านบน |
| `scripts/fcitx5-cycle.sh` | Cycles the input language between English, Japanese, and Thai. | สลับภาษาพิมพ์ระหว่างอังกฤษ ญี่ปุ่น และไทย |
| `scripts/larp` | Opens or closes a four-pane terminal wall containing Fetch, a clock, CMatrix, and Cava. | เปิดหรือปิด terminal สี่ช่องสำหรับ Fetch, นาฬิกา, CMatrix และ Cava |
| `scripts/ram` | Shows memory usage and can stop unnecessary user processes. | ดูว่าโปรแกรมไหนใช้ RAM และช่วยหยุด process ของผู้ใช้ที่ไม่จำเป็น |
| `scripts/unzzz` | Keeps the machine awake when the lid is closed and disables that mode when requested. | สั่งให้เครื่องตื่นต่อแม้ปิดฝา และยกเลิกโหมดนี้เมื่อต้องการ |

### Themes and wallpapers / ธีมและรูปพื้นหลัง

| File / ไฟล์ | English | ภาษาไทย |
|---|---|---|
| `themes/SCHEMA.md` | Documents supported theme values and which ones are required. | อธิบายว่าธีมหนึ่งชุดใส่ค่าอะไรได้บ้าง และค่าไหนจำเป็น |
| `themes/{harumi,nanami,natsume,nene,sana}/theme.conf` | Colors, wallpaper, opacity, and character details for complete themes. | สี wallpaper ความโปร่งใส และข้อมูลตัวละครของแต่ละธีมที่ใช้งานได้แล้ว |
| `themes/incomplete/{meguru,tsumuki}/theme.conf` | Incomplete themes waiting for wallpapers; theme pickers ignore them. | ธีมที่ยังขาด wallpaper จึงพักไว้ก่อนและไม่แสดงในตัวเลือกธีม |
| `themes/templates/<app>/*` | Configuration templates for Niri, Quickshell, terminals, and other themed applications. | แม่แบบ config ของ Niri, Quickshell, terminal และแอปอื่น ๆ ที่จะถูกเติมสีตามธีม |
| `wallpapers/*.jpg` | Wallpaper images used by complete themes. | รูปพื้นหลังของธีมที่ใช้งานได้ |

## Add another machine

Use the same three install commands. If its hostname is new, `install.sh` creates
`hosts/<hostname>/configuration.nix` and `hardware-configuration.nix`. Review and
commit those two machine-specific files afterward. Shared changes belong in
`nixos.nix`; personal applications belong in `home/moni.nix`.

## Copyright / ลิขสิทธิ์

This is a personal configuration repository. No license is granted for copying,
modifying, redistributing, or reusing its contents. All rights are reserved.
Third-party packages and wallpaper assets remain subject to their original
owners' terms.

นี่เป็น repository สำหรับ config ส่วนตัว ไม่ได้อนุญาตให้นำเนื้อหาไปคัดลอก
ดัดแปลง แจกจ่าย หรือนำไปใช้ต่อ สงวนสิทธิ์ทั้งหมด ส่วนแพ็กเกจและรูปภาพจากบุคคลอื่น
ยังคงเป็นไปตามเงื่อนไขของเจ้าของเดิม
