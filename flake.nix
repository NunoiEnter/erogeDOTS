{
  description = "erogeDOTS - The Pro Edition";

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qylock.url = "github:Darkkal44/qylock";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, qylock, zen-browser, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    catnap = pkgs.callPackage ./pkgs/catnap/default.nix {};
  in
  {
    packages.${system} = {
      inherit catnap;
      default = catnap;
    };

    nixosConfigurations = {
      NixChan = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/NixChan/hardware-configuration.nix
          ./hosts/NixChan/configuration.nix
          inputs.qylock.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit catnap zen-browser; };
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
