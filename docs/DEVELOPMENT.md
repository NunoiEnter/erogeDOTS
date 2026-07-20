# erogeDOTS Development & Theme System

Nix flake-based development environments + instant theme switching.

## Quick Start

```bash
cd ~/erogeDOTS

nix develop              # full shell (all languages combined)
nix develop .#rust       # Rust development
nix develop .#python     # Python development
nix develop .#go         # Go development
nix develop .#tester     # QA / Software testing
nix develop .#docker     # Docker & Podman containers
nix develop .#security   # Cyber security toolkit
nix develop .#common     # shared CLI tools only
```

## Shell Reference

### `default` (full)

All-in-one shell combining Rust, Python, Go, and common tools.

| Category | Tools |
|----------|-------|
| Rust | rustc, cargo, rust-analyzer, clippy, rustfmt, cargo-edit, cargo-watch, cargo-audit, cargo-deny |
| Python | python3, ruff, pyright, black, mypy, uv |
| Go | go, gopls, gofumpt, golangci-lint, govulncheck, air |
| Nix | nil, nixfmt-rfc-style |
| Common | git, lazygit, ripgrep, fd, jq, yq-go, prettier, shfmt, shellcheck, htop |

### `rust`

Rust toolchain with stable channel, language server, and cargo ecosystem.

```
rustc, cargo, rust-analyzer, clippy, rustfmt
cargo-edit    - add/remove/upgrade dependencies
cargo-watch   - rebuild on file change
cargo-audit   - security vulnerability check
cargo-deny    - dependency policy enforcement
```

**Environment:** `RUST_SRC_PATH` set for rust-analyzer.

**Usage:**
```bash
cargo init my-project
cargo watch -x check          # auto-check on save
cargo audit                    # scan for vulns
cargo deny check               # policy check
```

### `python`

Python 3 with modern tooling. Uses `uv` for fast package management.

```
python3, ruff, pyright, black, mypy, uv
pytest, pytest-html, pytest-cov
requests, httpx
```

**Usage:**
```bash
uv init my-project
uv add flask
uv run pytest                   # run tests
ruff check .                    # lint
ruff format .                   # format
pyright .                       # type check
```

### `go`

Go with language server, formatter, and linter.

```
go, gopls, gofumpt, golangci-lint
govulncheck, air (hot reload)
```

**Environment:** `GOPATH=$HOME/go`, `GOBIN=$HOME/go/bin`.

**Usage:**
```bash
go mod init myproject
gofumpt -l .                    # format
golangci-lint run               # lint
govulncheck ./...               # scan vulns
air                             # hot reload dev server
```

### `tester`

QA / Software testing shell. Multi-language testing tools.

| Category | Tools |
|----------|-------|
| Unit/Integration | pytest, pytest-html, pytest-xdist, pytest-cov |
| API | httpie, curl, jq |
| Load/Perf | k6, wrk, vegeta |
| Browser | playwright-driver, chromium |
| Mobile | adb-cli |
| Coverage | lcov, coverage |

**Usage:**
```bash
# API testing
httpie GET http://localhost:8080/api/health
curl -s http://localhost:8080/api/health | jq

# Load testing
k6 run --vus 10 --duration 30s script.js
echo "GET http://localhost:8080" | vegeta attack -duration=30s | vegeta report

# Browser testing
npx playwright install
npx playwright test

# Python tests
pytest tests/ -v --cov=src --html=report.html
```

### `docker`

Container development with Docker, Podman, and security scanning.

| Category | Tools |
|----------|-------|
| Runtimes | docker, docker-compose, podman, podman-compose |
| Image Tools | dive, skopeo, buildah, crane |
| Security | trivy, grype |
| Linting | hadolint |
| Debugging | ctop, lazydocker |
| Registry | regctl |

**Environment:** `DOCKER_HOST` points to Podman socket.

**Usage:**
```bash
# Build & scan
hadolint Dockerfile             # lint Dockerfile
docker build -t myapp .
trivy image myapp               # scan for vulns
dive myapp                      # analyze image layers

# Containers
docker compose up -d
lazydocker                      # TUI for docker

# Multi-runtime
podman build -t myapp .
podman compose up
```

### `security`

Cyber security toolkit. **Use only on authorized targets.**

| Category | Tools |
|----------|-------|
| Network Scanning | nmap, masscan, rustscan, netcat, socat |
| Web Testing | nikto, gobuster, ffuf, dirb, whatweb, sqlmap, wpscan |
| Exploitation | metasploit, searchsploit |
| Password Attacks | hydra, john, hashcat, ncrack |
| Wireless | aircrack-ng |
| Forensics | binwalk, foremost, strings, file, exiftool |
| Packet Analysis | wireshark, tcpdump, tshark |
| Vuln Scanning | nuclei, nuclei-templates |
| OSINT | theHarvester, sherlock |
| Crypto | openssl, age |
| Reverse Eng | ghidra, radare2 |

**Usage:**
```bash
# Network recon
nmap -sC -sV -oN scan.txt target.com
rustscan -a target.com -- -sV -sC

# Web enumeration
gobuster dir -u http://target.com -w /path/to/wordlist.txt
ffuf -u http://target.com/FUZZ -w wordlist.txt
nikto -h http://target.com

# SQL injection
sqlmap -u "http://target.com/page?id=1" --dbs

# Password brute force
hydra -l admin -P wordlist.txt target.com http-post-form "/login:user=^USER^&pass=^PASS^:F=incorrect"

# Vuln scanning
nuclei -u http://target.com -t nuclei-templates/

# Forensics
binwalk firmware.bin
exiftool image.jpg

# Packet capture
sudo tcpdump -i eth0 -w capture.pcap
```

## direnv Integration (Recommended)

Auto-load shells per-project. Add to `home/modules/terminal.nix`:

```nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
```

Then in each project directory:

```bash
# Rust project
echo "use flake ~/erogeDOTS#rust" > .envrc

# Python project
echo "use flake ~/erogeDOTS#python" > .envrc

# Go project
echo "use flake ~/erogeDOTS#go" > .envrc

# etc.
direnv allow
```

Shell loads automatically on `cd`.

## File Structure

```
erogeDOTS/
├── flake.nix              # Flake entry - devShells defined here
├── shells/
│   ├── common.nix         # Shared CLI tools
│   ├── rust.nix           # Rust dev
│   ├── python.nix         # Python dev
│   ├── go.nix             # Go dev
│   ├── full.nix           # All combined
│   ├── tester.nix         # QA / Testing
│   ├── docker.nix         # Container tools
│   └── security.nix       # Cyber security
├── themes/
│   ├── templates/         # Config templates with {{VARIABLES}}
│   │   ├── niri/config.kdl
│   │   ├── waybar/{config.jsonc,style.css}
│   │   ├── catnap/config.cat
│   │   └── fuzzel/config.ini
│   ├── harumi/            # Pink/cute theme (default)
│   ├── nanami/            # Dark purple/elegant
│   ├── natsume/           # Warm pastel/calm
│   └── nene/              # Lavender/dreamy
├── scripts/
│   └── theme-switch       # Theme switcher command
└── docs/
    └── DEVELOPMENT.md     # This file
```

## Theme Switcher

Instant desktop theme changer. Switches niri, waybar, fuzzel, catnap colors without rebuild.

### Quick Start

```bash
theme-switch list          # show available themes
theme-switch harumi        # switch to harumi theme (pink)
theme-switch nanami        # switch to nanami (dark purple)
theme-switch natsume       # switch to natsume (warm pastel)
theme-switch nene          # switch to nene (lavender)
theme-switch current       # show active theme
theme-switch preview       # preview current theme colors
```

### Aliases

```bash
ts                       # theme-switch
tslist                   # theme-switch list
tscurrent                # theme-switch current
tspreview                # theme-switch preview
```

### How It Works

1. `themes/<name>/theme.conf` defines color variables
2. `themes/templates/` contains config templates with `{{VARIABLE}}` placeholders
3. `theme-switch` generates configs by substituting variables
4. Generated configs cached in `~/.config/theme/cache/<name>/`
5. Symlinks point `~/.config/<app>` to generated configs
6. Affected apps restart (waybar) or reload (niri)

### Creating a New Theme

1. Create theme directory:

```bash
mkdir -p themes/mytheme
```

2. Create `themes/mytheme/theme.conf`:

```ini
[colors]
primary = "#your_color"
primary_light = "#lighter"
primary_dark = "#darker"
bg = "#background"
bg_light = "#lighter_bg"
bg_surface = "#surface"
fg = "#foreground"
fg_dim = "#dimmed"

# Waybar
waybar_bg_gradient = "linear-gradient(135deg, #color1 0%, #color2 100%)"
waybar_border = "#border_color"
waybar_shadow = "rgba(r, g, b, 0.25)"
waybar_text = "#text_color"
waybar_active_bg = "linear-gradient(135deg, #color1, #color2)"

# Niri
niri_focus_active = "#focus_color"
niri_focus_inactive = "#inactive_color"
niri_shadow = "#shadow_color"

# Fastfetch
ff_color = "magenta"

# Nvim
nvim_colorscheme = "your-colorscheme"

# Wallpaper
wallpaper = "~/Pictures/wallpapers/your-wallpaper.jpg"

# Icons
waybar_workspace_active = "◆"
waybar_workspace_default = "◇"
waybar_clock_icon = "🌸"
```

3. Switch to it:

```bash
theme-switch mytheme
```

### Template Variables

All `{{VARIABLES}}` in templates are replaced with values from `theme.conf`:

| Variable | Used In | Description |
|----------|---------|-------------|
| `{{PRIMARY}}` | waybar | Primary accent color |
| `{{PRIMARY_LIGHT}}` | waybar | Lighter accent |
| `{{PRIMARY_DARK}}` | waybar | Darker accent |
| `{{BG}}` | waybar, fuzzel | Background color |
| `{{FG}}` | waybar, fuzzel | Foreground color |
| `{{NIRI_FOCUS_ACTIVE}}` | niri | Active window focus ring |
| `{{NIRI_FOCUS_INACTIVE}}` | niri | Inactive window focus ring |
| `{{WAYBAR_BG_GRADIENT}}` | waybar | Background gradient |
| `{{WALLPAPER}}` | niri | Wallpaper path |

### Available Themes

| Theme | Style | Primary |
|-------|-------|---------|
| **harumi** | Pink/cute (default) | `#ff8fb1` |
| **nanami** | Dark purple/elegant | `#bd93f9` |
| **natsume** | Warm pastel/calm | `#cba6f7` |
| **nene** | Lavender/dreamy | `#b4a7d6` |

## Adding a New Shell

1. Create `shells/mylang.nix`:

```nix
{ pkgs }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # tools here
  ];

  shellHook = ''
    echo "🔧 MyLang shell loaded"
  '';
}
```

2. Add to `flake.nix` outputs:

```nix
devShells.${system} = {
  # ... existing shells ...
  mylang = import ./shells/mylang.nix { inherit pkgs; };
};
```

3. Test: `nix develop .#mylang`

## Notes

- All shells use `nativeBuildInputs` (correct for dev shells, not `buildInputs`)
- Language servers included where available (rust-analyzer, pyright, gopls)
- `RUST_SRC_PATH`, `GOPATH`, `GOBIN` set for IDE integration
- `shellHook` shows version info on shell entry
- Shells are reproducible - same tools on any NixOS machine
