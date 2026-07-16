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
  home.file = {
    ".config/niri".source = ../config/niri;
    ".config/waybar".source = ../config/waybar;
    ".config/fuzzel".source = ../config/fuzzel;
    ".config/foot".source = ../config/foot;
    ".config/fastfetch".source = ../config/fastfetch;
    ".config/nvim".source = ../config/nvim;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "26.05";
}
