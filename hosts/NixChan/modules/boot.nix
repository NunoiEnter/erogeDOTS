# hosts/NixChan/modules/boot.nix
# Bootloader. ESP 96M at /efi, /boot on root ext4 via GRUB.
{ lib, ... }:
{
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.timeout = 0;

  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "rd.udev.log_level=3" "rd.systemd.show_status=auto" ];
}
