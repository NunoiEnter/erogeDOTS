{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vesktop
    kdePackages.dolphin
    obs-studio
    waybar
    fuzzel
    awww
    wl-clipboard
    noto-fonts-cjk-sans
    tree
    wine
    steam
    heroic
    p7zip
    qbittorrent
  ];

}
