# home/modules/gaming.nix
# Game launchers + wine. System side (programs.steam) in hosts/NixChan/modules/gaming.nix.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wine
    steam
    steam-run
    heroic
  ];
}
