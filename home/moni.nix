{ config, pkgs, ... }:

{
  home.username = "moni";
  home.homeDirectory = "/home/moni";

  imports = [
    ./modules/terminal.nix
    ./modules/desktop.nix
  ];

  # Symlinks — niri, waybar, catnap, fuzzel managed by theme-switch
  home.file = {
    ".config/nvim".source = ../config/nvim;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "26.05";

  # Restore active theme on home-manager activation (only if cache missing)
  home.activation.restoreTheme = config.lib.homeManagerActivation.postActivationHook or "" + ''
    export PATH="$HOME/.local/bin:$PATH"
    STATE_FILE="$HOME/.config/theme/active"
    if [[ -f "$STATE_FILE" ]]; then
      THEME=$(cat "$STATE_FILE")
      CACHE_DIR="$HOME/.config/theme/cache/$THEME"
      if [[ ! -d "$CACHE_DIR" ]]; then
        SCRIPTS="$HOME/erogeDOTS/scripts"
        if [[ -x "$SCRIPTS/theme-switch" ]]; then
          "$SCRIPTS/theme-switch" "$THEME" 2>/dev/null || true
        fi
      fi
      if command -v ghostty &>/dev/null; then
        pkill -x "ghostty" -USR1 2>/dev/null || true
      fi
    fi
  '';
}
