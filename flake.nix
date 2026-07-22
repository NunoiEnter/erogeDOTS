{
  description = "erogeDOTS - The Pro Edition";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qylock.url = "github:Darkkal44/qylock";
  };

  outputs = { self, nixpkgs, home-manager, qylock, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    theme-picker = pkgs.callPackage ./pkgs/theme-picker/default.nix {};
    catnap = pkgs.callPackage ./pkgs/catnap/default.nix {};
  in
  {
    packages.${system} = {
      inherit theme-picker catnap;
      default = theme-picker;
    };

    nixosConfigurations = {
      NixChan = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/NixChan/hardware-configuration.nix
          ./hosts/NixChan/configuration.nix
          inputs.qylock.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit theme-picker catnap; };
            home-manager.users.moni = import ./home/moni.nix;
          }
        ];
      };
    };

    devShells.${system} = {
      default = import ./shells/full.nix { inherit pkgs; };
      rust = import ./shells/rust.nix { inherit pkgs; };
      python = import ./shells/python.nix { inherit pkgs; };
      go = import ./shells/go.nix { inherit pkgs; };
      common = import ./shells/common.nix { inherit pkgs; };
      tester = import ./shells/tester.nix { inherit pkgs; };
      docker = import ./shells/docker.nix { inherit pkgs; };
      security = import ./shells/security.nix { inherit pkgs; };
    };
  };
}
