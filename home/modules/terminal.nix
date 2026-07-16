{ pkgs, ... }:

{
  home.packages = with pkgs; [
    foot
    alacritty
    yazi
    fastfetch
    neovim
    ripgrep
    fd
    gcc
    gdb
    curl
    gnutar
    tree-sitter
    htop
    btop
    upower
    opencode
  ];

  home.sessionPath = [
    "$HOME/erogeDOTS/scripts"
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ts = "theme-switch";
      tslist = "theme-switch list";
      tscurrent = "theme-switch current";
      tspreview = "theme-switch preview";
    };
    initContent = ''
      fastfetch
      setopt PROMPT_SUBST
      PROMPT='%F{magenta}%m%f %F{white}%~%%f '
    '';
  };

  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "monospace:size=11";
        pad = "8x8";
        dpi-aware = "yes";
      };

      cursor = {
        style = "beam";
        blink = "yes";
      };

      mouse = {
        hide-when-typing = "yes";
      };

      "colors-dark" = {
        alpha = "0.85";
        background = "1a1b26";
        foreground = "c0caf5";
        regular0 = "15161e";
        regular1 = "f7768e";
        regular2 = "9ece6a";
        regular3 = "e0af68";
        regular4 = "7aa2f7";
        regular5 = "bb9af7";
        regular6 = "7dcfff";
        regular7 = "a9b1d6";
        bright0 = "414868";
        bright1 = "f7768e";
        bright2 = "9ece6a";
        bright3 = "e0af68";
        bright4 = "7aa2f7";
        bright5 = "bb9af7";
        bright6 = "7dcfff";
        bright7 = "c0caf5";
      };
    };
  };
}
