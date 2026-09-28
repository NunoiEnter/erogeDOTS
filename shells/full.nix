{ pkgs }:

let
  rust = import ./rust.nix { inherit pkgs; };
  python = import ./python.nix { inherit pkgs; };
  go = import ./go.nix { inherit pkgs; };
  common = import ./common.nix { inherit pkgs; };
in
pkgs.mkShell {
  nativeBuildInputs =
    rust.nativeBuildInputs
    ++ python.nativeBuildInputs
    ++ go.nativeBuildInputs
    ++ common.nativeBuildInputs
    ++ (with pkgs; [
      nil
      nixfmt
      govulncheck
      air
    ]);

  RUST_SRC_PATH = rust.RUST_SRC_PATH;
  GOPATH = "$HOME/go";
  GOBIN = "$HOME/go/bin";

  shellHook = ''
    echo "🚀 Full Dev Shell loaded"
    echo "   Rust $(rustc --version | awk '{print $2}') | Python $(python3 --version | awk '{print $2}') | Go $(go version | awk '{print $3}')"
  '';
}
