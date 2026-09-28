# hosts/NixChan/modules/gaming.nix
# System side of gaming. Game packages themselves live in home/modules/gaming.nix.
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
}
