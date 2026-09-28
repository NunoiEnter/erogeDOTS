# home/modules/desktop.nix
# Session tools: bar, launcher, notifications, screenshots, clipboard, power.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    quickshell
    fuzzel
    awww
    swaynotificationcenter
    libnotify
    xwayland-satellite
    upower
    brightnessctl
    playerctl
    wl-clipboard
    cliphist
    grim
    slurp
    swappy
    wlogout
    wlsunset
    swaylock
  ];
}
