{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "theme-picker";
  version = "0.1.0";
  src = lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      let name = builtins.baseNameOf path;
      in name != "target" && name != ".gitignore";
  };
  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Terminal theme picker for erogeDOTS";
    license = lib.licenses.mit;
    mainProgram = "theme-picker";
  };
}
