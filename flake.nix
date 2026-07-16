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

  outputs = { self, nixpkgs, home-manager, qylock, ... }@inputs: {
    nixosConfigurations = {
      NixChan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/NixChan/hardware-configuration.nix
          ./hosts/NixChan/configuration.nix
          inputs.qylock.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.moni = import ./home/moni.nix;
          }
        ];
      };
    };
  };
}
