{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vesktop
    kdePackages.dolphin
    kdePackages.ark          # archive manager — integrates with dolphin right-click
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
    unrar
    qbittorrent
    qimgv
    vlc
  ];

  # Dolphin dark theme via KDE color scheme
  xdg.configFile = {
    "kdeglobals".text = ''
      [General]
      ColorScheme=BreezeDark
      Theme=Breeze Dark
    '';
  };
}
