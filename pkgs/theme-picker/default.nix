{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "theme-picker";
  version = "0.1.0";

  src = ./../..;
  cargoRoot = "picker-rs";
  cargoLock.lockFile = ./../../picker-rs/Cargo.lock;

  buildAndTestSubdir = "picker-rs";

  doCheck = false;

  meta = with lib; {
    description = "TUI theme picker with kitty image protocol";
    license = licenses.mit;
    mainProgram = "theme-picker";
  };
}
