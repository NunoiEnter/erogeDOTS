# hosts/NixChan/modules/bluetooth.nix
# Off by default for RAM (<1G goal). Enable when a headset/speaker is needed.
# Plain false wins over GNOME's default-true. Flip to true to re-enable.
{
  hardware.bluetooth.enable = false;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = false;
}
