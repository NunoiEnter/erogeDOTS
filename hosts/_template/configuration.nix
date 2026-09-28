# Default host for a newly cloned machine. install.sh copies this directory and
# generates hardware-configuration.nix before evaluation.
{ lib, ... }:

{
  imports = [
    ../../nixos.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = lib.mkDefault (builtins.baseNameOf (toString ./.));

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.configurationLimit = 10;
}
