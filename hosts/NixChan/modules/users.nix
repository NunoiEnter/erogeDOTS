# hosts/NixChan/modules/users.nix
# User + passwordless sudo scoped to NixOS management (paste convenience only).
# The agent never runs nixos-rebuild headless; the user pastes the command.
{ pkgs, ... }:
{
  users.users.moni = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "dialout" ];
    shell = pkgs.zsh;
  };

  security.sudo.extraRules = [
    {
      users = [ "moni" ];
      commands = [
        { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nix-collect-garbage"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nix-store"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nix"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  system.stateVersion = "26.05";
}
