# hosts/NixChan/modules/fonts.nix
# Single source for fonts. google-fonts covers Kanit + Thai sets.
{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      google-fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];
    fontconfig = {
      defaultFonts = {
        sansSerif = [ "Kanit" "Noto Sans" ];
        serif = [ "Kanit" "Noto Serif" ];
        monospace = [ "JetBrainsMono Nerd Font" "Fira Code" ];
      };
    };
  };
}
