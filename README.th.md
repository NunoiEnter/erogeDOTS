# erogeDOTS — Alpha 1.4

[คู่มือภาษาอังกฤษ](README.md)

ชุดตั้งค่า NixOS ส่วนตัวของผู้ใช้ `moni` ใช้ Niri เป็นหน้าเดสก์ท็อปหลักและยังเก็บ GNOME ไว้เป็นตัวสำรอง โปรแกรม Kitty, Alacritty, Ghostty, Discord, Vesktop, Discordo และ OpenCode CLI ยังอยู่ครบ ส่วน bridge ที่เคยเชื่อม Discord กับ OpenCode ถูกลบหมดแล้ว

repo นี้เปิดเป็นสาธารณะเพื่อให้ผม clone ไปใช้กับเครื่องของตัวเองได้ง่าย ไม่ใช่ดิสโทร NixOS สำหรับคนทั่วไป และไม่ได้ให้สิทธินำไปใช้ต่อ

## โหมดมนุษย์ถ้ำ

Clone ให้ตรงที่ รัน installer ใส่รหัส sudo ครั้งเดียว ตัวติดตั้งเช็ก สร้าง เปิดใช้ คืน theme จบ

```bash
git clone <repository-url> /home/moni/erogeDOTS
cd /home/moni/erogeDOTS
./install.sh
```

จำสามปุ่มพอ: `Mod+Shift+/` เปิดคู่มือปุ่ม, `Mod+T` เปิด theme และ `Mod+Ctrl+D` เปิด dev shell

## คู่มือแบบคนทั่วไป

### การติดตั้ง

เครื่องต้องเป็น NixOS, มีผู้ใช้ชื่อ `moni`, วาง repo ที่ `/home/moni/erogeDOTS` และต่ออินเทอร์เน็ตสำหรับ build ครั้งแรก จากนั้น `install.sh` จะทำงานทั้งหมดนี้เอง:

1. เช็กชื่อผู้ใช้ ตำแหน่ง repo hostname ระบบ NixOS และคำสั่งที่จำเป็น
2. ขอสิทธิ์ sudo หนึ่งครั้ง เพราะการเปิดใช้ NixOS รุ่นใหม่ต้องใช้สิทธิ์ root
3. ตรวจ hostname ถ้าเป็นเครื่อง UEFI ใหม่ จะสร้าง `hosts/<hostname>/hardware-configuration.nix` ให้อัตโนมัติ
4. รัน `nix flake check` แล้ว build และ switch เครื่องนั้นโดยตรง
5. คืน theme ล่าสุด และตรวจว่าระบบกับ theme picker ถูกติดตั้งแล้ว
6. เก็บ log เต็มไว้ที่ `~/.local/state/erogedots/install.log`

เครื่อง `NixChan` ยังใช้ GRUB/EFI แบบเดิม ส่วนเครื่องใหม่ที่ระบบสร้างให้อัตโนมัติจะใช้ systemd-boot ควรตรวจและ commit ไฟล์ hardware ที่สร้างใหม่ก่อนใช้เป็นข้อมูลถาวร

### Secret

ห้าม commit token, กุญแจ VPN, SSH private key, รหัส Wi-Fi, cookie หรือไฟล์ `.env` เก็บสิ่งเหล่านี้ไว้นอก repo ใน password manager, repo ลับที่เข้ารหัส หรือไฟล์เฉพาะเครื่องที่ตั้งสิทธิ์ `0600` เปิด dotfiles เป็น public ได้ แต่ห้ามเปิด credential

### รูปแบบ config

`configuration.nix` คือ config ระบบร่วมเพียงไฟล์เดียว ไฟล์ `nixos.nix` และ wrapper ของแต่ละเครื่องเดิมไม่จำเป็นจึงถูกรวมแล้ว แต่ยังต้องมีไฟล์เล็กของแต่ละเครื่องคือ `hosts/<hostname>/hardware-configuration.nix` เพราะ UUID ของดิสก์ filesystem และ driver เป็นข้อเท็จจริงของ hardware ไม่ควรปนกับ config ที่ย้ายข้ามเครื่อง

Home Manager ดูแลโปรแกรมของผู้ใช้ alias ค่า MIME และ desktop file เมื่อเปิด Zsh terminal ปกติจะแสดง Fastfetch อัตโนมัติ ส่วน mini terminal แบบ animation จะข้าม Fastfetch ที่ซ้ำกัน ต้นฉบับ theme อยู่ใน `themes/` แล้ว `theme-switch` จะสร้าง config จริงลง `~/.config` ส่วน Neovim เหลือ bootstrap ไฟล์เดียวและใช้ค่าเริ่มต้นปกติของ LazyVim

### ปุ่มสำคัญของ Niri

`Mod` คือปุ่ม Super/Windows

| ปุ่ม | การทำงาน |
| --- | --- |
| `Mod+Shift+/` | เปิดหน้ารวม hotkey ของ Niri |
| `Mod+Return` | เปิด Ghostty |
| `Mod+Shift+Return` | เปิด terminal ลอยขนาดเล็ก |
| `Mod+grave` | เปิดหรือซ่อน dropdown terminal |
| `Mod+D` | เปิดตัวค้นหาโปรแกรม |
| `Mod+T` | เปิดตัวเลือก theme |
| `Mod+Shift+T` | สร้าง theme ผ่าน TUI ทีละขั้น |
| `Mod+Ctrl+D` | เลือก Nix development shell |
| `Mod+G` | เปิดหรือซ่อน terminal สี่ช่อง |
| `Mod+Ctrl+V` | เปิดประวัติ clipboard |
| `Mod+Alt+R` | เปิดหน้าดู RAM แบบสด |
| `Mod+Alt+Z` | เปิดหรือปิดโหมดไม่ให้เครื่องหลับเมื่อพับฝา |
| `Mod+S` | เปิดหรือปิด quick settings |
| `Mod+Shift+Space` | สลับภาษาอังกฤษ ญี่ปุ่น และไทย |
| `Super+Alt+L` | ล็อกหน้าจอ |
| `Mod+O` | เปิดหรือปิด overview |
| `Mod+Q` | ปิดหน้าต่างที่เลือก |
| `Mod+ลูกศร` หรือ `Mod+H/J/K/L` | ย้ายจุดโฟกัส |
| `Mod+Ctrl+ลูกศร` หรือ `Mod+Ctrl+H/J/K/L` | ย้ายหน้าต่าง |
| `Mod+1` ถึง `Mod+9` | ไป workspace |
| `Mod+Ctrl+1` ถึง `Mod+Ctrl+9` | ย้ายหน้าต่างไป workspace |
| `Mod+V` | สลับหน้าต่างลอย |
| `Mod+W` | สลับคอลัมน์แบบ tab |
| `Mod+F` / `Mod+Shift+F` | ขยายคอลัมน์ / เต็มจอ |
| `Print` / `Ctrl+Print` / `Alt+Print` | จับภาพพื้นที่ / จอ / หน้าต่าง |
| `Mod+Shift+W` | เปิดเมนูออกจากระบบ |

### สคริปต์ที่ใช้ประจำและคำสั่งสั้น

ทุกสคริปต์มีทางเรียกด้วย hotkey ชื่อที่ยาวมี alias สั้น ส่วนคำสั่งที่สั้นอยู่แล้วใช้ชื่อเดิม

| สคริปต์ | ใช้ทำอะไร | Hotkey | คำสั่งสั้น |
| --- | --- | --- | --- |
| `theme-switch` | สร้างและเปิดใช้ config ตาม theme | `Mod+T` | `ts`, `tspick`, `tsadd`, `tslist`, `tscurrent`, `tspreview` |
| `cliphist-pick` | เลือกประวัติ clipboard ผ่าน Fuzzel | `Mod+Ctrl+V` | `clip` |
| `dropterm` | เปิดหรือซ่อน Ghostty แบบ dropdown | `Mod+grave` | `drop` |
| `fcitx5-cycle.sh` | วนสลับ input method ที่ตั้งไว้ | `Mod+Shift+Space` | `ime` |
| `larp` | เปิดหรือซ่อน terminal สี่ช่อง | `Mod+G` | `larp` |
| `ram` | รายงาน เฝ้าดู หรือลดโปรแกรมที่กิน RAM | `Mod+Alt+R` | `ram` |
| `unzzz` | เปิด ปิด หรือสลับตัวกันเครื่องหลับเมื่อพับฝา | `Mod+Alt+Z` | `unzzz` |

### Theme

กด `Mod+T` หรือใช้ `ts` เพื่อเลือก theme ที่มีอยู่ ตัว picker จะแสดง wallpaper ข้างรายการ โดยใช้ระบบแสดงภาพของ terminal ถ้ารองรับ และใช้ภาพสีแบบครึ่งบล็อกเป็นตัวสำรอง กด `Mod+Shift+T` หรือใช้ `tsadd` เพื่อสร้างใหม่ Rust TUI จะถาม ID กับข้อมูลตัวละคร แล้วแสดงรูปจริงขณะเลื่อนเลือกรูปจาก `wallpapers/`, `~/Pictures` หรือ `~/Downloads` ขั้นเลือกชุดสีมี swatch และค่า hex จริงครบหกชุด จากนั้นหน้าปรับสีจะแสดงทุกช่องสีของ theme รวม Niri และ Bottom: กด `Enter` เลือกช่องสี, เลือก swatch, กด `Tab` เลือก R/G/B (หรือ alpha ของเงา), `←/→` ปรับทีละ 1, `[`/`]` ปรับทีละ 16 และ `s` เพื่อไปต่อ TUI จะคัดลอกรูปและเขียน `theme.conf` ให้ครบ ส่วน Fetch กับ Cmatrix รองรับแค่ชื่อสี จึงใช้ชื่อสีที่ใกล้ primary accent ที่เลือกที่สุด

ยังใช้คำสั่งตรงได้:

```bash
theme-switch list
theme-switch current
theme-switch preview harumi
theme-switch harumi
```

ถ้าจะเพิ่มด้วยมือ ให้คัดลอก `themes/<ชื่อ>/theme.conf` ที่สมบูรณ์พร้อม wallpaper ใช้ ID ตัวพิมพ์เล็กที่ปลอดภัย (`a-z`, `0-9`, `-`) แล้วรัน `theme-switch <ชื่อ>` แต่แนะนำให้ใช้ TUI เพราะมันใส่ค่าที่ template ต้องการให้ครบ

### Development shell

ใช้ `dev` หรือกด `Mod+Ctrl+D` แล้วเลือก `default`, `rust`, `python`, `go`, `java`, `common`, `tester`, `docker`, `security`, `webapp` หรือ `pg-computer` TUI จะเปิด `nix develop` ตัวที่เลือกให้ ใช้ตรงก็ยังได้ เช่น `nix develop .#rust` (`nix develop .#java` สำหรับ JDK 21 + Maven + Gradle + IntelliJ IDEA)

## หน้าที่ของทุกไฟล์ใน repo

รายการนี้ตั้งใจเขียนชื่อทุกไฟล์ให้ชัด ถ้ามีไฟล์อื่นนอกเหนือจากนี้ มันไม่ควรเป็นส่วนของ config สาธารณะ

### ตัว repo และ Nix

- `.gitattributes` — ทำให้ Git จัดการไฟล์ข้อความเหมือนกันทุกเครื่อง
- `.gitignore` — กันไฟล์ build, state ในเครื่อง, secret และไฟล์ที่สร้างอัตโนมัติออกจาก Git
- `README.md` — คู่มือภาษาอังกฤษฉบับเต็ม
- `README.th.md` — คู่มือภาษาไทยฉบับนี้
- `flake.nix` — จุดเริ่มของระบบ ค้นหา host, สร้าง package, ต่อ Home Manager และส่งออก dev shell
- `flake.lock` — ล็อกเวอร์ชัน input ทั้งหมดเพื่อให้ build ซ้ำได้เหมือนเดิม
- `configuration.nix` — config NixOS ร่วม รวม boot, service, desktop, input method, font และค่าความปลอดภัย
- `home/moni.nix` — package, alias, application, MIME และการคืน theme ของผู้ใช้
- `hosts/NixChan/hardware-configuration.nix` — ข้อมูล hardware ที่สร้างจากเครื่อง NixChan เท่านั้น
- `install.sh` — ตรวจระบบ หา host, build, เปิดใช้, คืน theme และตรวจผลท้ายงาน
- `shells.nix` — นิยาม development environment ทุกตัวที่เลือกได้

### Editor และ package ใน repo

- `config/nvim/init.lua` — bootstrap ขนาดเล็กของ Lazy.nvim ที่โหลด LazyVim แบบมาตรฐาน
- `picker-rs/Cargo.toml` — ข้อมูล package ของ Rust TUI และ dependency ที่ใช้โดยตรง
- `picker-rs/Cargo.lock` — เวอร์ชัน dependency Rust ที่แน่นอน
- `picker-rs/src/main.rs` — ตัวเลือก theme, ตัวสร้าง theme, ตัวเลือก dev shell และ unit test
- `pkgs/chatgpt/default.nix` — ห่อ ChatGPT desktop AppImage จากต้นทางให้เป็น Nix package

### สคริปต์

- `scripts/theme-switch` — ตรวจค่า theme, สร้าง template, ติดตั้ง config, เก็บ state และ reload desktop
- `scripts/cliphist-pick` — หน้าค้นหาประวัติ clipboard
- `scripts/dropterm` — ตัวควบคุม dropdown terminal
- `scripts/fcitx5-cycle.sh` — ตัววนสลับ input method
- `scripts/larp` — ตัวควบคุม terminal สี่ช่อง
- `scripts/ram` — ตัวรายงาน เฝ้าดู และช่วยลด RAM โดย OpenCode ยังเป็น CLI ปกติ
- `scripts/unzzz` — ตัวกัน lid-close ชั่วคราวผ่าน systemd รองรับ start, stop และ toggle

### ข้อมูล theme

- `themes/harumi/theme.conf` — ชุดสีและข้อมูลตัวละคร Harumi
- `themes/nanami/theme.conf` — ชุดสีและข้อมูลตัวละคร Nanami
- `themes/natsume/theme.conf` — ชุดสีและข้อมูลตัวละคร Natsume
- `themes/nene/theme.conf` — ชุดสีและข้อมูลตัวละคร Nene
- `themes/sana/theme.conf` — ชุดสีและข้อมูลตัวละคร Sana
- `wallpapers/harumi.jpg` — wallpaper ของ Harumi
- `wallpapers/nanami.jpg` — wallpaper ของ Nanami
- `wallpapers/natsume.jpg` — wallpaper ของ Natsume
- `wallpapers/nene.jpg` — wallpaper ของ Nene
- `wallpapers/sana.jpg` — wallpaper ของ Sana

### Template ที่ใช้สร้าง config

- `themes/templates/alacritty/alacritty.toml` — สีและความโปร่งใสของ Alacritty
- `themes/templates/cava/config` — สีของ Cava visualizer
- `themes/templates/cmatrix/config` — สีของ Cmatrix
- `themes/templates/fetch/config` — สีของข้อมูลระบบใน terminal
- `themes/templates/fuzzel/fuzzel.ini` — หน้าตาของตัวค้นหาโปรแกรม
- `themes/templates/ghostty/config` — สีและความโปร่งใสของ Ghostty
- `themes/templates/kitty/kitty.conf` — สีและความโปร่งใสของ Kitty
- `themes/templates/niri/config.kdl` — layout, กฎหน้าต่าง, โปรแกรมเริ่มต้น และ hotkey ทั้งหมดของ Niri
- `themes/templates/quickshell/shell.qml` — panel และ quick settings ที่รับสีจาก theme
- `themes/templates/swaync/config.json` — พฤติกรรมของ notification center
- `themes/templates/swaync/style.css` — สีและหน้าตาของ notification center

## ความเป็นเจ้าของและการนำไปใช้

สงวนลิขสิทธิ์ © 2026 moni

ตั้งใจไม่ใช้ MIT License การมองเห็น repo แบบ public มีไว้สำหรับ sync ส่วนตัวและใช้อ่านเป็นตัวอย่างเท่านั้น ไม่ได้ให้สิทธิคัดลอก แจกจ่าย เผยแพร่ ออก sublicense หรือขายเนื้อหา ส่วน dependency และซอฟต์แวร์จากต้นทางยังใช้ license ของตัวเอง
