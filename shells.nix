{ pkgs }:

let
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
  };

  rustTools = with pkgs; [
    rustToolchain cargo-edit cargo-watch cargo-audit cargo-deny cargo-bloat
    cargo-outdated
  ];
  pythonTools = with pkgs; [
    python3 python3Packages.ruff pyright uv python3Packages.black
    python3Packages.isort python3Packages.mypy python3Packages.pudb
  ];
  goTools = with pkgs; [
    go gopls gofumpt golangci-lint gotools go-tools govulncheck air
  ];
  commonTools = with pkgs; [
    git lazygit neovim nixfmt shfmt prettier shellcheck ripgrep fd jq yq-go tree
    htop file unzip curl wget
  ];

  mkShell = packages: attrs: pkgs.mkShell ({ nativeBuildInputs = packages; } // attrs);
in
{
  default = mkShell (rustTools ++ pythonTools ++ goTools ++ commonTools ++ (with pkgs; [ nil ])) {
    RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
    shellHook = ''
      echo "Full: Rust $(rustc --version | awk '{print $2}') | Python $(python3 --version | awk '{print $2}') | Go $(go version | awk '{print $3}')"
    '';
  };

  rust = mkShell rustTools {
    RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
    shellHook = ''echo "Rust $(rustc --version | awk '{print $2}')"'';
  };

  python = mkShell pythonTools {
    PYTHONBREAKPOINT = "pudb.set_trace";
    shellHook = ''echo "Python $(python3 --version | awk '{print $2}')"'';
  };

  go = mkShell goTools {
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
    shellHook = ''echo "Go $(go version | awk '{print $3}')"'';
  };

  common = mkShell commonTools {
    shellHook = ''echo "Common development tools loaded"'';
  };

  tester = mkShell (with pkgs; [
    python3 python3Packages.pytest python3Packages.pytest-html
    python3Packages.pytest-xdist python3Packages.pytest-cov python3Packages.requests
    python3Packages.httpx curl httpie jq k6 wrk vegeta nodejs pnpm
    playwright-driver chromium android-tools lcov python3Packages.coverage
    python3Packages.responses python3Packages.pytest-mock tree-sitter ripgrep fd
  ]) {
    shellHook = ''echo "Tester: pytest | playwright | k6 | httpie | vegeta"'';
  };

  docker = mkShell (with pkgs; [
    docker docker-compose podman podman-compose dive skopeo buildah crane trivy
    grype hadolint regctl ctop lazydocker jq yq-go curl wget git
  ]) {
    DOCKER_HOST = "unix:///var/run/podman/podman.sock";
    shellHook = ''echo "Containers: docker | podman | compose | trivy"'';
  };

  security = mkShell (with pkgs; [
    nmap masscan rustscan netcat-gnu socat nikto gobuster ffuf dirb whatweb
    sqlmap metasploit exploitdb hydra john hashcat ncrack aircrack-ng binwalk
    foremost binutils file exiftool wireshark tcpdump tshark nuclei
    nuclei-templates theharvester sherlock openssl age ghidra radare2 curl wget
    jq python3 python3Packages.requests git tmux ripgrep
  ]) {
    shellHook = ''
      echo "SECURITY LAB: use only on systems you own or may test."
    '';
  };

  webapp = mkShell (with pkgs; [ bun gh nodejs git ]) { };

  pg-computer = pkgs.mkShell {
    buildInputs = with pkgs; [
      python312 linuxHeaders gcc pkg-config grim slurp wl-clipboard ydotool wtype
      glib xdg-desktop-portal wlr-randr
    ];
    shellHook = ''
      export C_INCLUDE_PATH="${pkgs.linuxHeaders}/include:$C_INCLUDE_PATH"
      export NIX_CFLAGS_COMPILE="-I${pkgs.linuxHeaders}/include $NIX_CFLAGS_COMPILE"
      echo "pg-computer: Python $(python3.12 --version 2>&1 | awk '{print $2}')"
    '';
  };
}
