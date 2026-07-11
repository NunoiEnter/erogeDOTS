{ config, pkgs, ... }:

{
  home.username = "moni";
  home.homeDirectory = "/home/moni";

  # User-space packages ecosystem
  home.packages = with pkgs; [
    # Shells & Core Terminals
    foot
    alacritty
    yazi
    fastfetch

    # Applications
    vesktop
    kdePackages.dolphin
    obs-studio
    firefox

    # Toolchains & Development
    neovim
    vscode
    rustup
    nodejs
    gnumake

    # Wayland Ricing Ecosystem
    waybar
    fuzzel
    awww # Note: swww was renamed to awww in the latest channel packages
    dunst
    wl-clipboard
    rofi
    
    # Fonts Engine
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    fira-code
    fira-code-symbols
  ];

  # Zsh Integration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  # Let Home Manager handle itself
  programs.home-manager.enable = true;
  home.file.".config/niri/config.kdl".source = ./config.kdl;
  # Keep this synchronized with your initial system setup version
  home.stateVersion = "26.05";
}
