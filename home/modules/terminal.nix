{ pkgs, ... }:

{
  home.packages = with pkgs; [
    foot
    alacritty
    yazi
    fastfetch
    neovim
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      fastfetch
      setopt PROMPT_SUBST
      PROMPT='%F{magenta}%m%f %F{white}%~%%f '
    '';
  };
}
