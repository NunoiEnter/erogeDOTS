{ config, pkgs, ... }:

{
  home.username = "moni";
  home.homeDirectory = "/home/moni";

  # นำเข้าโมดูลที่แยกไว้
  imports = [
    ./modules/terminal.nix
    ./modules/desktop.nix
  ];

  # เชื่อมโยงโฟลเดอร์ตั้งค่า (Dotfiles)
  # Note: niri, waybar, fastfetch, fuzzel managed by theme-switch
  home.file = {
    ".config/nvim".source = ../config/nvim;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "26.05";
}
