{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vesktop
    kdePackages.dolphin
    obs-studio
    waybar
    fuzzel
    awww
    dunst
    wl-clipboard
    noto-fonts-cjk-sans
    fira-code
    tree
    wine
    steam
    vesktop
    heroic
    p7zip
    qbittorrent
  ];

}
