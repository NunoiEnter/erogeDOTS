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
    rustToolchain

    pkgs.cargo-edit
    pkgs.cargo-watch
    pkgs.cargo-audit
    pkgs.cargo-deny
    pkgs.cargo-bloat
    pkgs.cargo-outdated
  ];

  RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";

  shellHook = ''
    echo "🦀 Rust $(rustc --version | awk '{print $2}') | cargo $(cargo --version | awk '{print $2}')"
  '';
}
