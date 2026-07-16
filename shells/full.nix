{ pkgs }:

let
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "rust-src"
      "rust-analyzer"
      "clippy"
      "rustfmt"
    ];
  };
in
pkgs.mkShell {
  nativeBuildInputs = [
    # Rust
    rustToolchain
    pkgs.cargo-edit
    pkgs.cargo-watch
    pkgs.cargo-audit
    pkgs.cargo-deny

    # Python
    pkgs.python3
    pkgs.python3Packages.ruff
    pkgs.python3Packages.pyright
    pkgs.uv
    pkgs.python3Packages.black
    pkgs.python3Packages.mypy

    # Go
    pkgs.go
    pkgs.gopls
    pkgs.gofumpt
    pkgs.golangci-lint
    pkgs.govulncheck
    pkgs.air

    # Nix
    pkgs.nil
    pkgs.nixfmt-rfc-style

    # Common
    pkgs.git
    pkgs.lazygit
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
    pkgs.yq-go
    pkgs.nodePackages.prettier
    pkgs.shfmt
    pkgs.shellcheck
    pkgs.htop
    pkgs.curl
    pkgs.wget
    pkgs.tree
  ];

  RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
  GOPATH = "$HOME/go";
  GOBIN = "$HOME/go/bin";

  shellHook = ''
    echo "🚀 Full Dev Shell loaded"
    echo "   Rust $(rustc --version | awk '{print $2}') | Python $(python3 --version | awk '{print $2}') | Go $(go version | awk '{print $3}')"
  '';
}
