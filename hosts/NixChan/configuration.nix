# hosts/NixChan/configuration.nix
# Thin router. Every domain lives in modules/. Pick a file, not a line number.
{
  imports = [
    ./modules/boot.nix
    ./modules/network.nix
    ./modules/desktop.nix
    ./modules/audio.nix
    ./modules/power.nix
    ./modules/fonts.nix
    ./modules/i18n.nix
    ./modules/gaming.nix
    ./modules/bluetooth.nix
    ./modules/remote.nix
    ./modules/nix-settings.nix
    ./modules/users.nix
  ];
}
