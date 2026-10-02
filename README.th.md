# erogeDOTS — Alpha 2.1

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

เครื่องต้องเป็น NixOS, มีผู้ใช้ชื่อ `moni`, วาง repo ที่ `/home/moni/erogeDOTS` และต่ออินเทอร์เน็ตสำหรับ build ครั้งแรก รัน `./install.sh` ใน terminal เพื่อเปิดตัวติดตั้ง TUI เลือกอ่านคำแนะนำ เริ่มติดตั้ง หรือกลับโดยไม่เปลี่ยนระบบ ใส่รหัส sudo ใน terminal ปกติก่อนเริ่ม แล้วติดตามขั้นตอนจริงกับ log ได้ ใช้ `./install.sh --plain` สำหรับโหมดไม่โต้ตอบ หรือ `theme-picker install --preview` เพื่อดูตัวอย่างโดยไม่แก้ระบบ:

1. เช็กชื่อผู้ใช้ ตำแหน่ง repo hostname ระบบ NixOS และคำสั่งที่จำเป็น
2. ขอสิทธิ์ sudo หนึ่งครั้ง เพราะการเปิดใช้ NixOS รุ่นใหม่ต้องใช้สิทธิ์ root
3. ตรวจ hostname ถ้าเป็นเครื่อง UEFI ใหม่ จะสร้าง `hosts/<hostname>/hardware-configuration.nix` ให้อัตโนมัติ
4. รัน `nix flake check` แล้ว build และ switch เครื่องนั้นโดยตรง
5. คืน theme ล่าสุด และตรวจว่าระบบกับ theme picker ถูกติดตั้งแล้ว
6. เก็บ log เต็มไว้ที่ `~/.local/state/erogedots/install.log`

เครื่อง `NixChan` ยังใช้ GRUB/EFI แบบเดิม ส่วนเครื่องใหม่ที่ระบบสร้างให้อัตโนมัติจะใช้ systemd-boot ควรตรวจและ commit ไฟล์ hardware ที่สร้างใหม่ก่อนใช้เป็นข้อมูลถาวร

### Secret

ห้าม commit token, กุญแจ VPN, SSH private key, รหัส Wi-Fi, cookie หรือไฟล์ `.env` เก็บสิ่งเหล่านี้ไว้นอก repo ใน password manager, repo ลับที่เข้ารหัส หรือไฟล์เฉพาะเครื่องที่ตั้งสิทธิ์ `0600` เปิด dotfiles เป็น public ได้ แต่ห้ามเปิด credential

ฟีเจอร์ desktop ปัจจุบันไม่ต้องใช้ API token กรอกรหัส Wi-Fi / นำเข้ากุญแจ VPN ผ่าน **System Config → Network** ซึ่งเปิดหน้าตั้งค่า NetworkManager และเก็บข้อมูลไว้ในเครื่อง ไม่ใส่ในไฟล์ Nix หรือช่องแก้ source ปุ่ม NixOS & Niri ที่มีอยู่ยังอยู่ครบ เพิ่มกฎกัน `auth.json`, ชื่อไฟล์ SSH key, profile `.nmconnection` และ `secrets/` เข้า Git ด้วย

ตรวจ repo วันที่ 2 ตุลาคม 2026 ไม่พบรูปแบบ credential/private key ที่ตรวจได้ใน source หรือ object ของ Git แต่พบอีเมลส่วนตัวใน commit/tag จึงเปลี่ยนเป็น GitHub noreply และล้าง `agent.md`, ข้อมูลโครงการ `.opencode/` เก่า กับ `pkgs/discord-opencode/` ออกจากประวัติ ทั้งสอง branch และสาม tag ถูก rewrite แล้ว เนื้อหา release ปัจจุบันไม่เปลี่ยน อย่า merge ประวัติเก่าจากเครื่องอื่นกลับมา [คู่มือ GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) อธิบายเรื่อง cache และ clone ที่ force-push ลบแทนไม่ได้ การตรวจนี้ไม่รับประกันว่าจะจับ secret ได้ทุกแบบ

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
theme-switch style win98
theme-switch style vn
```

ถ้าจะเพิ่มด้วยมือ ให้คัดลอก `themes/<ชื่อ>/theme.conf` ที่สมบูรณ์พร้อม wallpaper ใช้ ID ตัวพิมพ์เล็กที่ปลอดภัย (`a-z`, `0-9`, `-`) แล้วรัน `theme-switch <ชื่อ>` แต่แนะนำให้ใช้ TUI เพราะมันใส่ค่าที่ template ต้องการให้ครบ

### Development shell

ใช้ `dev` หรือกด `Mod+Ctrl+D` แล้วเลือก `default`, `rust`, `python`, `go`, `java`, `common`, `tester`, `docker`, `security`, `webapp` หรือ `pg-computer` TUI จะเปิด `nix develop` ตัวที่เลือกให้ ใช้ตรงก็ยังได้ เช่น `nix develop .#rust` (`nix develop .#java` สำหรับ JDK 21 + Maven + Gradle + IntelliJ IDEA)

## ไฟล์สำคัญ

ส่วนนี้เป็นแผนที่ไฟล์ต้นทางหลัก ไม่ใช่รายการทุกไฟล์ ยังมี component และ check ที่เกี่ยวข้องอยู่ในโฟลเดอร์เดียวกัน

### ตัว repo และ Nix

- `.gitattributes` — ทำให้ Git จัดการไฟล์ข้อความเหมือนกันทุกเครื่อง
- `.gitignore` — กันไฟล์ build, state ในเครื่อง, secret และไฟล์ที่สร้างอัตโนมัติออกจาก Git
- `README.md` — คู่มือภาษาอังกฤษฉบับเต็ม
- `README.th.md` — คู่มือภาษาไทยฉบับนี้
- `flake.nix` — จุดเริ่มของระบบ ค้นหา host, สร้าง package, ต่อ Home Manager และส่งออก dev shell
- `flake.lock` — ล็อกเวอร์ชัน input ทั้งหมดเพื่อให้ build ซ้ำได้เหมือนเดิม
- `configuration.nix` — config NixOS ร่วม รวม boot, service, desktop, input method, font และค่าความปลอดภัย
- `home/moni.nix` — package, alias, application, MIME และการคืน theme ของผู้ใช้
- `home/desktop-packages.json` — รายการแอปเพิ่มที่ workshop และ Home Manager จัดการ
- `hosts/NixChan/hardware-configuration.nix` — ข้อมูล hardware ที่สร้างจากเครื่อง NixChan เท่านั้น
- `install.sh` — จุดเริ่มตัวติดตั้งแบบมีหน้าจอและโหมดไม่โต้ตอบ
- `shells.nix` — นิยาม development environment ทุกตัวที่เลือกได้

### Editor และ package ใน repo

- `config/nvim/init.lua` — bootstrap ขนาดเล็กของ Lazy.nvim ที่โหลด LazyVim แบบมาตรฐาน
- `picker-rs/Cargo.toml` — ข้อมูล package ของ Rust TUI และ dependency ที่ใช้โดยตรง
- `picker-rs/Cargo.lock` — เวอร์ชัน dependency Rust ที่แน่นอน
- `picker-rs/src/main.rs` — ตัวเลือก theme, ตัวสร้าง theme, หน้าติดตั้ง, ตัวเลือก dev shell และ unit test
- `picker-rs/src/bin/` — helper Rust สำหรับ workshop NixOS/Niri และ terminal บน title screen
- `picker-rs/src/installer.rs` และ `picker-rs/src/theme_json.rs` — workflow ติดตั้งและการจัดการข้อมูล theme
- `pkgs/chatgpt/default.nix` — ห่อ ChatGPT desktop AppImage จากต้นทางให้เป็น Nix package

### สคริปต์

- `scripts/theme-switch` — ตรวจค่า theme, สร้าง template, ติดตั้ง config, เก็บ state และ reload desktop
- `scripts/theme-picker` และ `scripts/rust-helper` — เลือกเครื่องมือ Rust จาก Nix หรือ build/cache helper ในเครื่อง
- `scripts/desktop-config` — เปิด backend ของ workshop
- `scripts/theme-curtain.qml` — ม่านดำบนทุกจอ อยู่ต่อระหว่าง restart shell แล้วจางออกเมื่อฉากใหม่พร้อม
- `scripts/vn-terminal` — เปิด terminal บน title screen และคืน workspace เดิมเมื่อปิด
- `scripts/vn-sound` — เล่นเสียง title และเสียง Exit ใช้ไฟล์เสียงส่วนตัวแทนได้

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
- `themes/templates/quickshell/` — title screen, theme studio, ตัวเลือกความสว่าง, workshop NixOS/Niri, hover drawer, bar และเมนู Windows 98 โดย `NiriState.qml` รับ event จาก Niri
- `themes/templates/quickshell/ThemeStudio.qml` และ `SystemWorkshop.qml` — สร้าง theme ผ่านหน้าจอและเครื่องมือ package, layout, config
- `themes/templates/quickshell/WorkspaceFlowchart.qml` — แผนผัง workspace ที่แตกแขนงไปยังหน้าต่างจริง กดเพื่อกลับไปยังจุดนั้น
- `themes/templates/quickshell/ActionIcon.qml` และ `VnAction.qml` — ไอคอนเส้นในเครื่องกับแถวเครื่องมือที่รองรับคีย์บอร์ด
- `tests/` — check แยกส่วนสำหรับ installer, การเปลี่ยนฉาก, keyboard, flowchart, workshop และ desktop actions
- `assets/sounds/` — เสียง title แบบ offline และเสียง session ที่สังเคราะห์ไว้ README อธิบายที่มาและวิธีแทนที่/ปิดเสียง
- `themes/templates/wlogout/` — เมนู session ที่ใช้สีเดียวกัน
- `themes/templates/swaync/config.json` — พฤติกรรมของ notification center
- `themes/templates/swaync/style.css` — สีและหน้าตาของ notification center

## เดสก์ท็อปสไตล์ Romance VN และ Windows 98

Alpha 2.1 ต่อยอดจาก snapshot **Alpha 2.0** ที่ tag [`alpha-2.0`](https://github.com/NunoiEnter/erogeDOTS/tree/alpha-2.0) โดยเพิ่มการควบคุมหน้าด้วยคีย์บอร์ด เมนู Exit แบบ VN ตัวติดตั้ง TUI การสร้าง theme ผ่านหน้า desktop การตั้งค่าความสว่างของ panel แยกจากแอป การค้นหา package จริง และตัวอย่าง layout ของ Niri คู่มือนี้อธิบาย source ปัจจุบันเวอร์ชัน 2.1

เมื่อเปิด Extra Mode, Music Room หรือ System Config โฟกัสจะไปที่ปุ่มแรกที่ใช้งานได้ ใช้ลูกศรเลือกปุ่มและ Enter เพื่อกด, Tab/Shift+Tab ไปยังตัวควบคุมถัดไปภายในหน้าเดิม พร้อมเลื่อนหน้าให้เห็นปุ่มที่เลือก Slider ใช้ซ้าย/ขวาปรับค่า ช่องตัวเลขและตัวแก้ไขข้อความยังใช้ปุ่มตามปกติ Escape กลับไปยังตัวเลือกเดิมใน title screen เมนูที่ปักหมุดจาก ribbon ใช้คีย์บอร์ดได้เช่นกัน

Exit มี **Sleep / Lock / Restart / Shutdown** แต่ละตัวเปิดคำถามยืนยัน โดยโฟกัสเริ่มที่ **No, stay here** เสมอ Escape ยกเลิกได้ เสียงเริ่มต้นเป็นเสียงระฆังสั้นที่สร้างขึ้นเอง ยังไม่ใช่เสียงตัวละคร เพิ่มเสียงทักทายของคุณที่ `~/.config/erogedots/sounds/greeting.ogg` ดู [รายละเอียดและลิงก์ system voice ทางการของ Senren＊Banka](assets/sounds/README.md)

`./install.sh` เปิดหน้าติดตั้ง TUI แบบ VN เลือกอ่านคำแนะนำ เริ่มติดตั้ง หรือกลับโดยไม่เปลี่ยนระบบได้ ใส่รหัส sudo ใน terminal ปกติก่อนเริ่ม แล้วดูขั้นตอนจริงกับ log ขณะติดตั้ง `./install.sh --plain` ใช้แบบไม่โต้ตอบ และ `theme-picker install --preview` ดูตัวอย่างโดยไม่ติดตั้ง ไฟล์ build ที่ ignore และประวัติ Git ไม่ถูกคัดลอกเข้าตัว build

เปลี่ยนตัวละครหรือสไตล์แล้วฉากเก่าจางดำ 280 ms จากนั้นเตรียม theme และภาพใหม่หลังม่าน ก่อนเปิดฉาก title ที่พร้อมแล้วด้วย fade 450 ms โดยไม่มีหน้า Load หรือข้อความเตรียมฉากแทรก Wallpaper บน desktop จางเปลี่ยน 800 ms ที่ 60 fps

สไตล์ Romance VN เปิดหน้าจอชื่อเรื่องเต็มจอด้วย `Mod+S` (Super+S) ใช้ wallpaper ตัวละคร เมนูสองภาษา ฟอนต์ serif และ panel สีครีม **New Game** เปิดตัวค้นหาโปรแกรม, **Load** เลือกตัวละครและ wallpaper, **Continue** กลับเดสก์ท็อป, **Flowchart** เลือก workspace หรือหน้าต่าง, **Music Room** ควบคุมเพลง, **Extra Mode** เปิดเครื่องมือ, **System Config** ปรับระบบ และ **Exit** เปิดเมนู session เลือกด้วยลูกศรขึ้น/ลงหรือ Tab แล้วกด Enter หรือ Enter บนแป้นตัวเลข กด Escape เพื่อกลับจากหน้าที่เลือกสู่เมนูหลัก แล้วกดอีกครั้งเพื่อปิด `Mod+D` เปิด launcher โดยตรง และ `Mod+Shift+W` เปิดเมนู session

กด **Terminal** หรือ Super+Enter ระหว่างเปิดหน้าจอชื่อเรื่องเพื่อเปิด Ghostty แบบลอยบนภาพตัวละคร ใช้ workspace ว่างและกลับ workspace เดิมเมื่อปิด terminal กด **Menu focus** เพื่อให้คีย์บอร์ดควบคุมเมนูอีกครั้ง และ **Terminal** เพื่อกลับไปพิมพ์คำสั่ง นอกหน้าจอชื่อเรื่อง Super+Enter เปิด terminal ตามปกติ

Music Room มี spectrum 48 แถบจาก CAVA จับเสียงจริงของ output ปัจจุบัน ใช้ process เดียวเฉพาะตอนเปิดหน้าเพลง ถ้าไม่มีเสียงจะแสดงแถบราบ

ใน **System Config → NixOS & Niri** แท็บ **Packages** ตรวจสอบชื่อ package กับ Nixpkgs ที่ pin ไว้และบันทึกใน `home/desktop-packages.json` แท็บ **Niri layout** ปรับช่องว่าง กรอบ focus และความกว้าง column ส่วน **Config files** แก้ไฟล์ NixOS, Home Manager หรือ Niri พร้อมตรวจ syntax และ backup ไว้ใน `~/.local/state/erogedots/config-backups/` ถ้าไฟล์ถูกแก้จากที่อื่นจะไม่เขียนทับ ใช้ **Apply Niri** เพื่อ reload เดสก์ท็อป, **Check NixOS** เพื่อตรวจ flake และ **Apply NixOS** เพื่อ rebuild ผ่าน terminal ที่ถามรหัสผ่าน ปิด title terminal เดิมก่อนเริ่มงานใหม่ การ build ใช้สำเนาชั่วคราวของไฟล์ที่ track และไฟล์ใหม่ที่ไม่ถูก ignore จึงไม่รวมประวัติ Git หรือ build artifact ที่ถูก ignore

ชี้เมาส์ที่ **Dashboard**, **Music Room**, **Chapters**, **Characters** หรือ **Sound** บนแถบด้านบนเพื่อให้ panel เลื่อนลงอย่างนุ่มนวล เมนูจะค้างเมื่อเลื่อนเมาส์เข้าไปใช้งานและปิดเมื่อออกจากบริเวณ คลิกชื่อเมนูเพื่อปักหมุด แล้วคลิกซ้ำ กด Escape หรือใช้ **Return** เพื่อปิด Gallery ตัวละครเปลี่ยน theme จริงและเปิดกลับมาแสดงตัวที่เลือก Music Room แสดงปกจากโปรแกรมเล่นเพลง ถ้าไม่มีปกจะแสดงแผ่นดิสก์แทน

ปุ่ม **Style** ข้าง **Character theme** สลับระหว่าง Romance VN กับ Windows 98 ซึ่งใช้พื้นสีเทา ปุ่มเหลี่ยมนูน และแถบชื่อสีน้ำเงินเข้ม เก็บสไตล์แยกไว้ใน `~/.config/theme/style` จึงเปลี่ยนตัวละครได้โดยไม่เสียสไตล์ที่เลือก และเปลี่ยนสไตล์ได้โดยคงตัวละครกับ wallpaper เดิมไว้ Launcher, notification, เมนู session และมุมหน้าต่าง Niri เปลี่ยนตามสไตล์ด้วย

แถบ VN มี tray, เสียง, notification log และนาฬิกา เลื่อนล้อเมาส์บน **Chapters** เพื่อสลับ workspace หรือบน **Sound** เพื่อปรับเสียง คลิกขวาที่ **Sound** เพื่อปิดเสียง Dashboard และ **System Config** แสดงสถานะเครือข่าย แบตเตอรี่ ความสว่าง และเสียง ส่วน Bluetooth ไม่พร้อมใช้เมื่อไม่มี adapter ที่เปิดอยู่ Windows 98 ยังคงเมนูระบบแบบมีกรอบและแถบสถานะพร้อมปุ่มเพลงและความสว่าง ทั้งสองสไตล์คลิกขวาที่ notification เพื่อสลับ Do Not Disturb และที่ tray เพื่อเปิดเมนูของโปรแกรม คลิกนาฬิกาเพื่อดูปฏิทิน แล้วกด Escape หรือคลิกด้านนอกเพื่อปิด

ปรับสี UI ด้วย `vn_paper`, `vn_ink`, `vn_muted`, `vn_accent`, `vn_tint`, `vn_line` ใน `theme.conf` โดย theme เก่าที่ยังไม่มีค่าเหล่านี้จะใช้สีครีมและชมพูเป็นค่าเริ่มต้น Terminal ยังใช้สีเข้มและความทึบ 92% อาจต้องเปิดหน้าต่าง terminal ใหม่เพื่อรับค่า

แก้ template ใน repo แล้วใช้ `theme-switch <name>` เพื่อ apply ระบบจะสร้างไฟล์ QML ย่อยและ `qmldir` พร้อม restart เฉพาะ shell นี้ ไม่ควรแก้ไฟล์ที่สร้างใน `~/.config` โดยตรง

**Flowchart** เป็นแผนผังจริง: workspace เรียงลงตามเส้นหลัก หน้าต่างที่เปิดแตกกิ่งไปด้านขวา จุดที่ใช้อยู่มีสีเน้น Workspace ว่างยังแสดง และไม่ปนหน้าต่างของจออื่น คลิกจุด หรือใช้ Tab/ลูกศรแล้ว Enter เพื่อกลับไปใช้งาน

**Extra Mode** มีไอคอนกับคำอธิบายของ notification, clipboard, terminal, dropdown, terminal สี่ช่อง และ lock แล้ว ลูกศรออกหมายถึงเปิดเครื่องมืออีกตัว ส่วน Lock ยังถามยืนยัน **System Config** แยกกลุ่มเครือข่าย/เสียงกับธีม/ระบบ มีสถานะ On/Off จริงและปิดปุ่ม Bluetooth เมื่อใช้ไม่ได้ Character theme, Desktop style และ NixOS & Niri เดิมยังอยู่ครบ เพิ่มไอคอนเล็กเฉพาะสองรายการนี้บน title โดยเก็บรูปแบบ title และ Exit เดิม

เปลี่ยนตัวละคร/สไตล์: ฉากเก่าจางดำ 280 ms → เตรียม config และภาพใหม่หลังม่าน → จางออก 450 ms เข้าหน้า title หลัก ไม่มีหน้า Load หรือข้อความเตรียมฉากแทรก ใช้ `theme-switch <name>` ปกติจะกลับ desktop; เพิ่ม `--show-menu` จะกลับ title กดซ้ำระหว่างเปลี่ยนไม่ได้ ถ้าล้มเหลวจะเปิดม่านและคืนปุ่ม มีตัวจับเวลา 30 วินาทีกันจอดำค้างด้วย

เปิด title หลักแล้วมีเสียงผู้หญิงสังเคราะห์พูด **“eroDOTS”** หนึ่งครั้ง ไม่พูดซ้ำเวลาเปลี่ยนหน้าย่อย ใช้งานออฟไลน์ เปลี่ยนเสียงที่ `~/.config/erogedots/sounds/title.ogg` หรือสร้างไฟล์ว่าง `~/.config/erogedots/sounds/mute` เพื่อปิดเสียง VN ทั้งหมด ดู [ที่มาเสียงและรูปแบบไฟล์ที่รองรับ](assets/sounds/README.md)

ไฟล์ส่วนนี้: `themes/templates/quickshell/WorkspaceFlowchart.qml` วาดแผนผัง workspace/หน้าต่าง, `assets/sounds/title.wav` เก็บเสียง title, `assets/sounds/README.md` อธิบายที่มาและการเปลี่ยนเสียง, `tests/flowchart.qml` ตรวจปุ่ม/หน้าต่าง/จอแคบ และ `tests/theme-transition.py` ตรวจลำดับเปลี่ยนฉากกับการคืนจอเมื่อผิดพลาดโดยไม่แตะ session จริง

ตรวจสอบการสร้าง theme และพฤติกรรม shell:

```sh
python3 tests/theme-render.py
python3 tests/theme-transition.py # จำลอง desktop ไม่ restart session จริง
bash tests/desktop-config.sh
bash tests/title-terminal.sh
bash tests/check-niri-state.sh
bash tests/check-drawer-state.sh
bash tests/check-tool-pages.sh # จำลองคำสั่ง ไม่เปลี่ยน session จริง
bash tests/check-title-keys.sh # ต้องมี Qt 6 qmltestrunner หรือกำหนด QMLTESTRUNNER
```

## ความเป็นเจ้าของและการนำไปใช้

สงวนลิขสิทธิ์ © 2026 moni

ตั้งใจไม่ใช้ MIT License การมองเห็น repo แบบ public มีไว้สำหรับ sync ส่วนตัวและใช้อ่านเป็นตัวอย่างเท่านั้น ไม่ได้ให้สิทธิคัดลอก แจกจ่าย เผยแพร่ ออก sublicense หรือขายเนื้อหา ส่วน dependency และซอฟต์แวร์จากต้นทางยังใช้ license ของตัวเอง

### UI เพิ่มธีมและโหมดสว่าง/มืด

เปิด **Load → Add a character** เพื่อเพิ่มธีมในหน้าต่างเดสก์ท็อป กรอก ID และชื่อ เลือกภาพ PNG/JPEG/WebP และพาเลตสี มีภาพตัวอย่างและแก้สีแยกได้ กด **Create theme** เพื่อบันทึก แล้ว **Apply theme** เพื่อใช้งาน ธีมเดิมจะไม่ถูกเขียนทับ

**Load → Appearance** แยก **VN panels** กับ **System apps** จึงใช้ UI สว่างกับแอปมืด หรือ UI มืดกับแอปสว่างได้ ตัวเลือกคงอยู่เมื่อเปลี่ยนตัวละคร Windows 98 ยังใช้สีเทาเดิม

หน้า **Packages** ค้นหาข้อมูลจริงจาก Nixpkgs รุ่นที่ล็อกใน flake.lock พร้อมชื่อ รุ่น คำอธิบาย และไอคอนแอปที่มีในเครื่อง หากไม่มีใช้โลโก้ Nix จากนั้นเพิ่มแพ็กเกจและกด Apply NixOS หน้า **Niri layout** มีตัวอย่างระยะห่าง ขอบหน้าต่าง และความกว้าง

ตัวช่วยตั้งค่าและเทอร์มินัลเปลี่ยนจาก Python เป็น Rust ส่วน ram ใช้เครื่องมือ Linux ปกติ เก็บ Lua ของ LazyVim และ Python สำหรับ dev/test ไว้ ระบบ portal ที่แก้ไขจะมีผลหลัง rebuild NixOS
