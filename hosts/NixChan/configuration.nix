# NixChan-only hardware and boot choices. Shared system config lives in ../../nixos.nix.
{ lib, ... }:

{
  imports = [
    ../../nixos.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "NixChan";

  # The 96 MiB ESP is mounted at /efi; GRUB reads /boot from the root filesystem.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;
    configurationLimit = 10;
  };
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/efi";
  };
  boot.loader.timeout = 0;
}
