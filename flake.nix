{
  description = "erogeDOTS ALPHA 1.4 - personal NixOS fleet";

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
    discord-opencode-bot = pkgs.callPackage ./pkgs/discord-opencode {};
    theme-picker = pkgs.callPackage ./picker-rs {};

    hostEntries = builtins.readDir ./hosts;
    hostNames = builtins.filter
      (name:
        hostEntries.${name} == "directory"
        && !(lib.hasPrefix "_" name)
        && builtins.pathExists (./hosts + "/${name}/configuration.nix"))
      (builtins.attrNames hostEntries);

    mkHost = hostName: lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        (./hosts + "/${hostName}/configuration.nix")
        inputs.qylock.nixosModules.default

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit chatgpt discord-opencode-bot theme-picker;
          };
          home-manager.users.moni = import ./home/moni.nix;
        }
      ];
    };
  in
  {
    packages.${system} = {
      inherit chatgpt discord-opencode-bot theme-picker;
    };

    nixosConfigurations = lib.genAttrs hostNames mkHost;

    devShells.${system} = import ./shells.nix { inherit pkgs; };
  };
}
