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

## แต่ละไฟล์เอาไว้ทำอะไร

ส่วนหลักของระบบ:

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| `flake.nix` | เป็นจุดเริ่มต้นของโปรเจกต์ บอก Nix ว่าจะใช้แหล่งแพ็กเกจอะไร มีเครื่องไหนบ้าง และมีโปรแกรมหรือชุดเครื่องมืออะไรให้สร้างได้ |
| `flake.lock` | ล็อกเวอร์ชันของทุก dependency เพื่อให้ติดตั้งวันนี้หรือย้ายไปอีกเครื่องแล้วได้ผลเหมือนเดิม |
| `nixos.nix` | ตั้งค่าระบบที่ใช้ร่วมกันทุกเครื่อง เช่น ผู้ใช้ เครือข่าย SSH เดสก์ท็อป เสียง พลังงาน ภาษา ฟอนต์ และ Steam |
| `home/moni.nix` | ตั้งค่าส่วนของผู้ใช้ `moni` เช่น โปรแกรมทั่วไป Kitty, Alacritty, Ghostty, Foot, Zsh, Firefox, แอปเริ่มต้น และ Discord bot service |
| `install.sh` | ตัวติดตั้งอัตโนมัติ ตรวจชื่อเครื่องและ hardware จากนั้นตรวจ config, build, เปิดใช้ระบบใหม่ และเช็กว่าติดตั้งสำเร็จ |
| `shells.nix` | รวมชุดเครื่องมือสำหรับงานพัฒนา เช่น Rust, Python, Go, Web, Docker, Testing และ Security |
| `.gitignore` | บอก Git ว่าไฟล์ไหนไม่ควรถูกอัปโหลด เช่นไฟล์ build, local cache และไฟล์ที่อาจมี secret |
| `.gitattributes` | ช่วยให้ GitHub แสดงชนิดไฟล์และสถิติภาษาใน repo ได้เหมาะสม |
| `LICENSE` | ระบุว่าโค้ดใน repo ใช้สัญญาอนุญาตแบบ MIT |

ค่าของแต่ละเครื่องและ Neovim:

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| `hosts/NixChan/configuration.nix` | ค่าเฉพาะเครื่อง NixChan เช่นชื่อเครื่องและวิธีบูตด้วย GRUB/EFI |
| `hosts/NixChan/hardware-configuration.nix` | ข้อมูล hardware และพาร์ทิชันของ NixChan ที่ NixOS ตรวจพบ |
| `hosts/_template/configuration.nix` | แม่แบบสำหรับเพิ่มเครื่องใหม่ โดยเริ่มจากค่า UEFI และ systemd-boot ที่ปลอดภัย |
| `config/nvim/init.lua` | ไฟล์แรกที่ Neovim โหลด แล้วส่งต่อไปยัง config ส่วนอื่น |
| `config/nvim/lua/config/*.lua` | เก็บปุ่มลัด ตัวเลือก พฤติกรรมอัตโนมัติ และระบบโหลด plugin ของ Neovim |
| `config/nvim/lua/plugins/init.lua` | รายชื่อและการตั้งค่า plugin ที่ Neovim ต้องใช้ |

โปรแกรมที่สร้างเองใน repo:

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| `picker-rs/Cargo.toml` / `Cargo.lock` | รายชื่อ library และเวอร์ชันที่ใช้สร้างโปรแกรมเลือกธีม |
| `picker-rs/src/main.rs` | ตัวโปรแกรมเลือกธีมแบบหน้าจอใน terminal พร้อมดูสีและ wallpaper ก่อนเลือก |
| `picker-rs/default.nix` | สอน Nix ว่าต้อง build และติดตั้ง theme picker อย่างไร |
| `pkgs/chatgpt/default.nix` | แพ็ก ChatGPT Linux ให้ติดตั้งและเปิดผ่าน NixOS ได้ |
| `pkgs/discord-opencode/Cargo.toml` / `Cargo.lock` | รายชื่อ library และเวอร์ชันของ Discord–OpenCode bridge |
| `pkgs/discord-opencode/default.nix` | สอน Nix ให้ build Discord–OpenCode bridge |
| `pkgs/discord-opencode/discord-bot.env.example` | ตัวอย่างชื่อค่าที่ bot ต้องใช้ เป็นไฟล์ว่างและไม่มี token จริง |
| `pkgs/discord-opencode/src/*.rs` | โค้ดของ bot แยกตามหน้าที่ เช่น Discord, OpenCode, permission, project, settings และ task |

สคริปต์ที่ใช้ประจำ:

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| `scripts/theme-switch` | อ่านค่าธีม สร้าง config ของแต่ละแอป เปลี่ยน wallpaper และ reload แอปที่เกี่ยวข้อง |
| `scripts/cliphist-pick` | เปิดรายการ clipboard เก่าให้ค้นหาและเลือกนำกลับมาใช้ |
| `scripts/dropterm` | เปิดหรือซ่อน Ghostty แบบ terminal เลื่อนลงจากด้านบน |
| `scripts/fcitx5-cycle.sh` | สลับภาษาพิมพ์ระหว่างอังกฤษ ญี่ปุ่น และไทย |
| `scripts/larp` | เปิดหรือปิด terminal สี่ช่องสำหรับ fetch, นาฬิกา, CMatrix และ Cava |
| `scripts/ram` | ดูว่าโปรแกรมไหนใช้ RAM และมีคำสั่งช่วยหยุด process ของผู้ใช้ที่ไม่จำเป็น |
| `scripts/unzzz` | สั่งให้เครื่องตื่นต่อแม้ปิดฝา และยกเลิกโหมดนี้เมื่อต้องการ |

ธีมและ wallpaper:

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| `themes/SCHEMA.md` | อธิบายว่าธีมหนึ่งชุดใส่ค่าอะไรได้บ้าง และค่าไหนจำเป็น |
| `themes/{harumi,nanami,natsume,nene,sana}/theme.conf` | สี wallpaper ความโปร่งใส และข้อมูลตัวละครของแต่ละธีมที่ใช้งานได้แล้ว |
| `themes/incomplete/{meguru,tsumuki}/theme.conf` | ธีมที่ยังขาด wallpaper จึงพักไว้ก่อนและไม่แสดงในตัวเลือกธีม |
| `themes/templates/<app>/*` | แม่แบบ config ของ Niri, Quickshell, terminal และแอปอื่น ๆ ที่จะถูกเติมสีตามธีม |
| `wallpapers/*.jpg` | รูปพื้นหลังของธีมที่ใช้งานได้ |

## Add another machine

Use the same three install commands. If its hostname is new, `install.sh` creates
`hosts/<hostname>/configuration.nix` and `hardware-configuration.nix`. Review and
commit those two machine-specific files afterward. Shared changes belong in
`nixos.nix`; personal applications belong in `home/moni.nix`.

## License

Code is MIT licensed. Wallpapers and upstream package assets keep their original
rights and are not relicensed by this repository.
