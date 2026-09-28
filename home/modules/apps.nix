# home/modules/apps.nix
# Daily apps: browsers, files, media, chat, editors. Games live in gaming.nix.
{ pkgs, chatgpt, ... }:
{
  home.packages = with pkgs; [
    firefox
    librewolf
    google-chrome
    vesktop
    kdePackages.dolphin
    kdePackages.ark
    obs-studio
    qimgv
    vlc
    mpv
    yt-dlp
    ytui-music
    qbittorrent
    p7zip
    unrar
    foliate
    figma-linux
    zed-editor
    arduino-ide
    arduino-cli
    tree
    discord
    discordo
    rustdesk
    chatgpt
  ];
}
