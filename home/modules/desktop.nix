{ pkgs, ... }:

let
  # Wrapper: opens nvim in ghostty from Dolphin
  nvim-desktop = pkgs.writeTextFile {
    name = "nvim-terminal.desktop";
    destination = "/share/applications/nvim-terminal.desktop";
    text = ''
      [Desktop Entry]
      Name=Neovim (Terminal)
      Exec=${pkgs.ghostty}/bin/ghostty -e ${pkgs.neovim}/bin/nvim %F
      Type=Application
      Terminal=false
      MimeType=text/plain;text/x-python;text/x-csrc;text/x-chdr;text/x-java;text/html;text/css;text/javascript;text/x-shellscript;application/json;application/xml;application/x-nix;
      Categories=TextEditor;Utility;
      Icon=utilities-terminal
    '';
  };
in
{
  home.packages = with pkgs; [
    vesktop
    kdePackages.dolphin
    kdePackages.ark
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
    nvim-desktop
  ];

  # Default app associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = "nvim-terminal.desktop";
      "text/x-python" = "nvim-terminal.desktop";
      "text/x-csrc" = "nvim-terminal.desktop";
      "text/x-chdr" = "nvim-terminal.desktop";
      "text/x-java" = "nvim-terminal.desktop";
      "text/html" = "nvim-terminal.desktop";
      "text/css" = "nvim-terminal.desktop";
      "text/javascript" = "nvim-terminal.desktop";
      "text/x-shellscript" = "nvim-terminal.desktop";
      "application/json" = "nvim-terminal.desktop";
      "application/xml" = "nvim-terminal.desktop";
      "application/x-nix" = "nvim-terminal.desktop";
      "image/*" = "qimgv.desktop";
      "video/*" = "vlc.desktop";
      "audio/*" = "vlc.desktop";
    };
  };

  # Dolphin dark theme
  xdg.configFile = {
    "kdeglobals".text = ''
      [General]
      ColorScheme=BreezeDark
      Theme=Breeze Dark
    '';
  };
}
