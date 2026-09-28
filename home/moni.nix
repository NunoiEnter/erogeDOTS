{ config, lib, pkgs, chatgpt, discord-opencode-bot, theme-picker, ... }:

let
  repo = "${config.home.homeDirectory}/erogeDOTS";
  discordEnv = "${config.home.homeDirectory}/.config/opencode/discord-bot.env";

  nvimDesktop = pkgs.writeTextFile {
    name = "nvim-terminal.desktop";
    destination = "/share/applications/nvim-terminal.desktop";
    text = ''
      [Desktop Entry]
      Name=Neovim (Terminal)
      Exec=${pkgs.ghostty}/bin/ghostty -e ${pkgs.neovim}/bin/nvim %F
      Type=Application
      Terminal=false
      MimeType=text/plain;text/x-python;text/x-csrc;text/x-chdr;text/x-java;text/html;text/css;text/javascript;text/x-shellscript;application/json;application/xml;application/x-nix;
      Categories=TextEditor;Utility;
      Icon=utilities-terminal
    '';
  };

  mimeapps = ''
    [Default Applications]
    x-scheme-handler/http=firefox.desktop
    x-scheme-handler/https=firefox.desktop
    x-scheme-handler/about=firefox.desktop
    text/html=firefox.desktop
    application/xhtml+xml=firefox.desktop
    text/plain=nvim-terminal.desktop
    text/x-python=nvim-terminal.desktop
    text/css=nvim-terminal.desktop
    text/javascript=nvim-terminal.desktop
    text/x-shellscript=nvim-terminal.desktop
    application/json=nvim-terminal.desktop
    application/xml=nvim-terminal.desktop
    application/x-nix=nvim-terminal.desktop
    image/png=qimgv.desktop
    image/jpeg=qimgv.desktop
    image/gif=qimgv.desktop
    image/webp=qimgv.desktop
    image/svg+xml=qimgv.desktop
    image/bmp=qimgv.desktop
    image/tiff=qimgv.desktop
    video/mp4=vlc.desktop
    video/x-matroska=vlc.desktop
    video/webm=vlc.desktop
    video/x-msvideo=vlc.desktop
    video/quicktime=vlc.desktop
    audio/mpeg=vlc.desktop
    audio/ogg=vlc.desktop
    audio/flac=vlc.desktop
    audio/x-wav=vlc.desktop
    audio/aac=vlc.desktop
    audio/mp4=vlc.desktop
    x-scheme-handler/figma=figma-linux.desktop
    x-scheme-handler/figmadesktop=figma-linux.desktop
  '';
in
{
  home = {
    username = "moni";
    homeDirectory = "/home/moni";
    stateVersion = "26.05";
    sessionPath = [
      "$HOME/.npm-global/bin"
      "$HOME/erogeDOTS/scripts"
    ];
    sessionVariables.EROGEDOTS_ROOT = repo;

    packages = with pkgs; [
      # Terminals and shell tools
      ghostty kitty alacritty foot vim git wget curl gnutar yazi fzf fetch

      # Desktop
      quickshell fuzzel awww swaynotificationcenter libnotify
      xwayland-satellite upower brightnessctl playerctl wl-clipboard cliphist
      grim slurp swappy wlogout wlsunset swaylock

      # Applications
      librewolf google-chrome vesktop kdePackages.dolphin kdePackages.ark
      obs-studio qimgv vlc mpv yt-dlp ytui-music qbittorrent p7zip unrar
      foliate figma-linux zed-editor arduino-ide arduino-cli tree discord
      discordo rustdesk chatgpt

      # Development
      neovim vscodium go cargo rustc bun gh opencode claude-code codex gcc gdb
      ripgrep fd jq htop btop tree-sitter

      # Gaming and media
      wine steam steam-run heroic rmpc

      # Terminal toys
      cava cmatrix hollywood pipes-rs tty-clock asciiquarium oneko cbonsai
      lolcat figlet fortune neo-cowsay pokemon-colorscripts sl chafa imagemagick

      nvimDesktop
      theme-picker
    ];

    file = {
      ".config/nvim".source = ../config/nvim;
      ".config/opencode/discord-bot.env.example".source =
        ../pkgs/discord-opencode/discord-bot.env.example;
    };
  };

  programs.home-manager.enable = true;

  # Browser preferences are declarative; install.sh no longer copies user.js.
  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      settings = {
        "gfx.webrender.all" = true;
        "gfx.webrender.enabled" = true;
        "gfx.webrender.compositor.force-enabled" = true;
        "layers.acceleration.force-enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "widget.wayland-dmabuf-vaapi.enabled" = true;
        "font.name.sans-serif.x-western" = "Kanit";
        "font.name.serif.x-western" = "Kanit";
        "font.name.monospace.x-western" = "JetBrains Mono";
        "font.size.variable.x-western" = 16;
        "font.size.fixed.x-western" = 14;
        "browser.aboutConfig.showWarning" = false;
      };
    };
  };

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
      mini = "fetch --frames 60";
      music = "rmpc";
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
    };
    initContent = ''
      setopt PROMPT_SUBST
      PROMPT='%F{magenta}%m%f %F{white}%~%%f '
      [[ -f "$HOME/.config/theme/env" ]] && source "$HOME/.config/theme/env"
    '';
  };

  xdg.configFile."mimeapps.list" = {
    text = mimeapps;
    force = true;
  };
  xdg.dataFile."applications/mimeapps.list".text = mimeapps;
  xdg.dataFile."applications/figma-linux.desktop".text = ''
    [Desktop Entry]
    Name=Figma Linux
    Comment=Unofficial Figma desktop application for Linux
    Exec=figma-linux %U
    Icon=figma-linux
    Terminal=false
    Type=Application
    Version=1.5
    MimeType=x-scheme-handler/figma;x-scheme-handler/figmadesktop;
  '';
  xdg.dataFile."applications/claude-webapp.desktop".text = ''
    [Desktop Entry]
    Name=Claude
    Comment=Claude by Anthropic (web app)
    Exec=firefox --new-window https://claude.ai %U
    Icon=claude
    Terminal=false
    Type=Application
    Version=1.5
    Categories=Network;Chat;
  '';
  xdg.configFile."kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark
    Theme=Breeze Dark
  '';

  services.mpd = {
    enable = false;
    musicDirectory = "${config.home.homeDirectory}/Music";
    playlistDirectory = "${config.home.homeDirectory}/Music/playlists";
    network = {
      listenAddress = "127.0.0.1";
      port = 6600;
    };
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Output"
      }
    '';
  };

  # Credentials live in this mode-0600 file, never Nix or Git.
  home.activation.createDiscordOpencodeBotEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -e "${discordEnv}" ]]; then
      install -Dm600 \
        "$HOME/.config/opencode/discord-bot.env.example" \
        "${discordEnv}"
    fi
  '';
  systemd.user.services.discord-opencode-bot = {
    Unit = {
      Description = "Oko-chan Discord bridge for OpenCode";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      ConditionPathExists = discordEnv;
    };
    Service = {
      ExecStart = "${discord-opencode-bot}/bin/discord-opencode-bot";
      Environment = [ "PATH=${lib.makeBinPath [ pkgs.opencode ]}" ];
      EnvironmentFile = discordEnv;
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      UMask = "0077";
    };
    Install.WantedBy = lib.mkForce [];
  };

  home.activation.restoreTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    state_file="$HOME/.config/theme/active"
    if [[ -f "$state_file" ]]; then
      theme="$(cat "$state_file")"
      if [[ ! -d "$HOME/.config/theme/cache/$theme" ]] \
        && [[ -x "${repo}/scripts/theme-switch" ]]; then
        EROGEDOTS_ROOT="${repo}" EROGEDOTS_NO_RESTART=1 \
          "${repo}/scripts/theme-switch" "$theme" 2>/dev/null || true
      fi
    fi
  '';
}
