{ pkgs, theme-picker, catnap, ... }:

{
  home.packages = with pkgs; [
    theme-picker
    catnap
    ghostty
    kitty
    alacritty
    foot
    vscodium
    foliate
    chafa
    go
    yazi
    neovim
    swaynotificationcenter
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
    brightnessctl
    blueman
    bluez
    bluez-tools
    libnotify
    nerd-fonts.jetbrains-mono
    xwayland-satellite
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
      yt = "mpv --ytdl-format=bestvideo[height<=1080]+bestaudio/best";
      ytmp3 = "yt-dlp -x --audio-format mp3";
      ytsearch = "yt-dlp \"ytsearch10:";
    };
    initContent = ''
      setopt PROMPT_SUBST
      PROMPT='%F{magenta}%m%f %F{white}%~%%f '

      # Catnap on open — cache for clear redraw
      _FF_CACHE="$HOME/.cache/catnap_output"
      if command -v catnap >/dev/null 2>&1; then
        catnap > "$_FF_CACHE" 2>/dev/null
        cat "$_FF_CACHE"
      fi

      # clear redraws catnap
      clear() {
        command clear "$@"
        [[ -f "$_FF_CACHE" ]] && cat "$_FF_CACHE"
      }
    '';
  };
}
