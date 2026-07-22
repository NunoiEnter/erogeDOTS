{ pkgs, system, affinity-nix, ... }:

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

  mimeapps = ''
    [Default Applications]
    text/plain=nvim-terminal.desktop
    text/x-python=nvim-terminal.desktop
    text/x-csrc=nvim-terminal.desktop
    text/x-chdr=nvim-terminal.desktop
    text/x-java=nvim-terminal.desktop
    text/html=nvim-terminal.desktop
    text/css=nvim-terminal.desktop
    text/javascript=nvim-terminal.desktop
    text/x-shellscript=nvim-terminal.desktop
    application/json=nvim-terminal.desktop
    application/xml=nvim-terminal.desktop
    application/x-nix=nvim-terminal.desktop
    image/png=qimgv.desktop
    image/jpeg=qimgv.desktop
    image/gif=qimgv.desktop
    image/webp=qimgv.desktop
    image/svg+xml=qimgv.desktop
    image/bmp=qimgv.desktop
    image/tiff=qimgv.desktop
    video/mp4=vlc.desktop
    video/x-matroska=vlc.desktop
    video/webm=vlc.desktop
    video/x-msvideo=vlc.desktop
    video/quicktime=vlc.desktop
    audio/mpeg=vlc.desktop
    audio/ogg=vlc.desktop
    audio/flac=vlc.desktop
    audio/x-wav=vlc.desktop
    audio/aac=vlc.desktop
    audio/mp4=vlc.desktop
  '';
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
    steam-run
    heroic
    p7zip
    unrar
    qbittorrent
    qimgv
    vlc
    nvim-desktop
    affinity-nix.packages.${system}.v3
  ];

  # Write mimeapps.list to BOTH locations KDE checks
  xdg.configFile."mimeapps.list".text = mimeapps;
  xdg.dataFile."applications/mimeapps.list".text = mimeapps;

  # Dolphin dark theme
  xdg.configFile."kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark
    Theme=Breeze Dark
  '';
}
