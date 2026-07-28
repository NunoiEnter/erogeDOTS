{ pkgs, catnap, ... }:

{
  home.packages = with pkgs; [
    catnap
    ghostty
    kitty
    alacritty
    foot
    vscodium
    foliate
    chafa
    imagemagick
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
    cava
    cmatrix
    hollywood
    pipes-rs
    tty-clock
    asciiquarium
    oneko
    cbonsai
    lolcat
    figlet
    fortune
    neo-cowsay
    pokemon-colorscripts
    sl
    rmpc
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
      cmx = "cmatrix -C \${CMATRIX_COLOR:-cyan}";
      cave = "cava -p ~/.config/cava/config";
      hwood = "hollywood";
      pipes = "pipes-rs -t $(tput cols) -r 0.5";
      ttyclock = "tty-clock -C \${CMATRIX_COLOR:-cyan} -s -g";
      aqua = "asciiquarium";
      catgo = "oneko";
      treeg = "cbonsai -l";
      rainbows = "fortune -s | cowsay | lolcat";
      pkmn = "pokemon-colorscripts -r 1 --no-title | lolcat";
      shout = "figlet -f small -c | lolcat";
      train = "sl";
      mini = "catnap -c $HOME/.config/catnap/config-mini.cat";
      music = "rmpc";
    };
    initContent = ''
      setopt PROMPT_SUBST
      PROMPT='%F{magenta}%m%f %F{white}%~%%f '

      # Theme env (cava, cmatrix colors)
      if [[ -f "$HOME/.config/theme/env" ]]; then
        source "$HOME/.config/theme/env"
      fi

      # Catnap on open — cache for clear redraw (skip in mini terminal)
      _FF_CACHE="$HOME/.cache/catnap_output"
      if [[ -z "$MINI" ]] && command -v catnap >/dev/null 2>&1; then
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
