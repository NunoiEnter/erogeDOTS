# hosts/NixChan/modules/nix-settings.nix
# Flakes, caches, GC. Keep ~10 generations (boot limit 10, rebuild ~every 3d).
{ lib, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (builtins.parseDrvName pkg.name).name [
    "wine" "steam" "heroic" "google-chrome"
  ];
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = lib.mkForce [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cachix.cachix.org"
    ];
    trusted-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cachix.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWg4T3M2wMCcO6n4T0L2TNA="
    ];
    fallback = true;
    connect-timeout = 15;
    stalled-download-timeout = 30;
    download-attempts = 3;
    http-connections = 8;
    max-substitution-jobs = 4;
    max-jobs = "auto";
    cores = 0;
    min-free = "5G";
    max-free = "20G";
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;
}
