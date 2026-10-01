{
  description = "erogeDOTS ALPHA 2.0 - visual novel NixOS desktop";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qylock.url = "github:Darkkal44/qylock";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, qylock, rust-overlay, ... }@inputs:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ rust-overlay.overlays.default ];
      config.allowUnfree = true;
    };
    chatgpt = pkgs.callPackage ./pkgs/chatgpt/default.nix {};
    theme-picker = pkgs.rustPlatform.buildRustPackage {
      pname = "theme-picker";
      version = "0.2.0";
      src = lib.cleanSourceWith {
        src = ./picker-rs;
        filter = path: type: type != "directory" || builtins.baseNameOf path != "target";
      };
      cargoLock.lockFile = ./picker-rs/Cargo.lock;
      meta = {
        description = "Theme and development-shell TUI for erogeDOTS";
        mainProgram = "theme-picker";
      };
    };

    hostEntries = builtins.readDir ./hosts;
    hostNames = builtins.filter
      (name:
        hostEntries.${name} == "directory"
        && !(lib.hasPrefix "_" name)
        && builtins.pathExists (./hosts + "/${name}/hardware-configuration.nix"))
      (builtins.attrNames hostEntries);

    mkHost = hostName: lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs hostName; };
      modules = [
        ./configuration.nix
        (./hosts + "/${hostName}/hardware-configuration.nix")
        inputs.qylock.nixosModules.default

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = {
            inherit chatgpt theme-picker;
          };
          home-manager.users.moni = import ./home/moni.nix;
        }
      ];
    };
  in
  {
    packages.${system} = {
      inherit chatgpt theme-picker;
    };

    nixosConfigurations = lib.genAttrs hostNames mkHost;

    devShells.${system} = import ./shells.nix { inherit pkgs; };
  };
}
