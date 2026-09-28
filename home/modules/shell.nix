# home/modules/shell.nix
# Terminal emulators + zsh. Aliases live with their owner (fun aliases in fun.nix).
{ pkgs, catnap, ... }:
{
  home.packages = with pkgs; [
    catnap
    ghostty
    kitty
    alacritty
    foot
    vim
    git
    wget
    curl
    gnutar
    yazi
    fzf
    fetch
  ];

  home.sessionPath = [
    "$HOME/.npm-global/bin"
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
      tspick = "theme-switch picker";
      yt = "mpv --ytdl-format=bestvideo[height<=1080]+bestaudio/best";
      ytmp3 = "yt-dlp -x --audio-format mp3";
      ytsearch = "yt-dlp \"ytsearch10:\"";
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
