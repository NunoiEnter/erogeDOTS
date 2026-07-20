{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kitty
    chafa
    go
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
    fzf
    cargo
    rustc
  ];

  home.sessionPath = [
    "$HOME/erogeDOTS/scripts"
    "$HOME/.local/bin"
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
      setopt PROMPT_SUBST
      PROMPT='%F{magenta}%m%f %F{white}%~%%f '
    '';
  };

  # kitty managed by theme-switch (themes/templates/kitty/kitty.conf)
  programs.kitty.enable = true;
}
