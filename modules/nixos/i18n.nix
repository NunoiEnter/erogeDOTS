# modules/nixos/i18n.nix
# Import from hosts/NixChan/configuration.nix:
#   imports = [ ../../modules/nixos/i18n.nix ];
{ pkgs, ... }:
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5.waylandFrontend = true;

    fcitx5.addons = with pkgs; [
      fcitx5-mozc          # Japanese engine
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
      # No package needed for Thai: Thai script types directly
      # (like Latin), so fcitx5's built-in "keyboard" addon
      # handles it via the XKB "th" layout — see keyboard-th below.
    ];

    # Declaratively register EN / JP / TH as a fixed cycle,
    # so you don't have to configure this by hand in the GUI.
    fcitx5.settings.inputMethod = {
      GroupOrder."0" = "Default";
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "us";
        DefaultIM = "keyboard-us";
      };
      "Groups/0/Items/0".Name = "keyboard-us";
      "Groups/0/Items/1".Name = "mozc";
      "Groups/0/Items/2".Name = "keyboard-th";
    };
  };

  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
  };

  # Noto CJK covers Japanese glyphs. Thai fonts (Noto Sans Thai /
  # Sarabun / IBM Plex Sans Thai) — grab whichever you already used
  # for your lab sheets; google-fonts includes all three.
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    google-fonts
  ];
}
