{ config, lib, pkgs, chatgpt, theme-picker, ... }:

let
  repo = "${config.home.homeDirectory}/erogeDOTS";
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

  ffDisplay = {
    separator = ": ";
    color = {
      keys = "magenta";
      title = "cyan";
    };
  };

  ffModules = [
    "title"
    "separator"
    "os"
    {
      type = "host";
      key = "󰌢 Device";
      format = "{family}";
    }
    {
      type = "kernel";
      format = "{release}";
    }
    "uptime"
    {
      type = "packages";
      combined = true;
    }
    "shell"
    {
      type = "wm";
      key = "WM";
    }
    "terminal"
    {
      type = "cpu";
      format = "{name}";
    }
    {
      type = "memory";
      format = "{used} / {total} ({percentage})";
    }
    {
      type = "disk";
      folders = [ "/" ];
      key = "Disk";
      format = "{size-used} / {size-total} ({size-percentage})";
    }
    {
      type = "battery";
      key = "Battery";
      format = "{capacity} [{status}]";
    }
    "break"
    {
      type = "colors";
      symbol = "circle";
    }
  ];

  # Compact info set: fits 61 cols, 9 rows. Full set used with big logo only.
  ffMiniModules = [
    "title"
    "separator"
    "os"
    {
      type = "kernel";
      format = "{release}";
    }
    "uptime"
    "shell"
    {
      type = "memory";
      format = "{used} / {total} ({percentage})";
    }
    "break"
    {
      type = "colors";
      symbol = "circle";
    }
  ];
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
      ghostty kitty alacritty vim git wget curl gnutar yazi fzf fetch fastfetch eza

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

    file.".config/nvim".source = ../config/nvim;
  };

  programs.home-manager.enable = true;

  # bottom binary via home-manager; bottom.toml itself is rendered by
  # theme-switch (themes/templates/bottom) so theme changes apply without
  # rebuilds — same pattern as ghostty/cava/fetch. Settings left empty
  # on purpose: a non-empty settings set would fight theme-switch over
  # ~/.config/bottom/bottom.toml.
  programs.bottom.enable = true;

  # Browser preferences are declarative; install.sh no longer copies user.js.
  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      path = "tg7nhhxp.default-1787541953087";
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
    # HM compinit deferred below (paints fetch inside niri animation); keep fpath setup only.
    enableCompletion = false;
    # Deferred below with compinit (paint first); keep HM fpath only.
    autosuggestion.enable = false;
    syntaxHighlighting.enable = false;
    shellAliases = {
      els = "eza -l --sort=size --icons --no-permissions --no-user --no-time --total-size" ;
      tslist = "theme-switch list";
      tscurrent = "theme-switch current";
      tspreview = "theme-switch preview";
      tspick = "theme-switch picker";
      tsadd = "theme-switch add";
      dev = "theme-picker dev";
      clip = "cliphist-pick";
      drop = "dropterm";
      ime = "fcitx5-cycle.sh";
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
      sc = "source ~/.zshrc" ;
    };
    initContent = ''
      setopt PROMPT_SUBST
      PROMPT='%F{magenta}%m%f %F{white}%~%%f '
      [[ -f "$HOME/.config/theme/env" ]] && source "$HOME/.config/theme/env"
      # ts wrapper: switch theme, then reload theme vars in THIS shell.
      # (A script can't touch its parent shell, so `source` must live here.)
      ts() {
        theme-switch "$@" && source "$HOME/.config/theme/env"
      }
      # Deferred shell init: runs on first prompt (after fetch paints),
      # so window animation + fetch appear together. Split hooks: slow compinit
      # can never cancel the fast plugins, even with Ctrl-C.
      autoload -Uz add-zsh-hook compinit
      _eroge_plugins() {
        add-zsh-hook -d precmd _eroge_plugins
        ZSH_AUTOSUGGEST_STRATEGY=(history)
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      }
      _eroge_compinit() {
        add-zsh-hook -d precmd _eroge_compinit
        local dump="''${ZSH_COMPDUMP:-$HOME/.zcompdump}"
        # Dump older than current system = stale store paths -> full rebuild once.
        if [[ ! -s "$dump" ]] || { [[ -e /run/current-system ]] && [[ "$dump" -ot /run/current-system ]]; }; then
          compinit -d "$dump" 2>/dev/null || true
        else
          compinit -C -d "$dump" 2>/dev/null || compinit -d "$dump"
        fi
      }
      add-zsh-hook precmd _eroge_plugins
      add-zsh-hook precmd _eroge_compinit
      # Instant theme-matched fetch: cat cache now (~5ms), refresh in background.
      # Cache keyed by theme primary so theme switches never show stale colors.
      _eroge_fetch() {
        local cfg="$1" tag tkey cache tmp k tg l1 l2 l3
        local -a flags
        tkey="''${THEME_PRIMARY:-#ff8fb1}"; tkey="''${tkey//[#]/}"
        tag="$2-$tkey"
        cache="$HOME/.cache/fastfetch-$tag.out"
        _FF_LAST="$cache"
        k="''${THEME_PRIMARY:-#ff8fb1}"; tg="''${THEME_FG:-#c0caf5}"
        l1="''${THEME_PRIMARY_DARK:-#5277c3}"; l2="''${THEME_PRIMARY:-#7ebae4}"; l3="''${THEME_PRIMARY_LIGHT:-#df90af}"
        flags=(--pipe false --color-keys "$k" --color-title "$tg" --logo-color-1 "$l1" --logo-color-2 "$l2" --logo-color-3 "$l3")
        if [[ -n "$cfg" ]]; then flags+=(-c "$cfg"); fi
        if [[ -s "$cache" ]]; then
          cat "$cache"
          tmp="$cache.$$"
          (fastfetch "''${flags[@]}" > "$tmp" 2>/dev/null && mv -f "$tmp" "$cache") &!
        else
          fastfetch "''${flags[@]}" | tee "$cache"
        fi
      }
      clear() {
        command clear "$@"
        [[ -n "''${_FF_LAST:-}" && -f "$_FF_LAST" ]] && cat "$_FF_LAST"
      }
      # Responsive: full NixOwOS logo needs 80x19,
      # else compact mini logo (fits 61 cols, 10 rows), skip when tiny.
      if [[ "''${EROGEDOTS_NO_FASTFETCH:-0}" != 1 ]]; then
        _ff_c="''${COLUMNS:-80}" _ff_l="''${LINES:-24}"
        if (( _ff_c >= 80 )) && (( _ff_l >= 19 )) && [[ -z "''${MINI:-}" ]]; then
          _eroge_fetch "" full
        elif (( _ff_l >= 10 )); then
          _eroge_fetch "$HOME/.config/fastfetch/compact.jsonc" compact
        fi
        unset _ff_c _ff_l
      fi
    '';
  };

  xdg.configFile."mimeapps.list" = {
    text = mimeapps;
    force = true;
  };
  # NixOwOS branding: full uwu logo for big windows, mini uwu logo + trimmed info otherwise
  # (ascii by u/ant-arctica via yunfachi/NixOwOS, CC-BY-4.0; mini variant own code).
  # File logos, no fastfetch overlay rebuild. Drops noisy Unknown modules
  # (de/wmtheme/theme/icons/font/terminalfont/swap/localip/poweradapter), compact display + circle colors.
  xdg.configFile."fastfetch/nixowos.txt".source = ../config/fastfetch/nixowos.txt;
  xdg.configFile."fastfetch/nixowos-mini.txt".source = ../config/fastfetch/nixowos-mini.txt;
  xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = {
      type = "file";
      source = "${config.home.homeDirectory}/.config/fastfetch/nixowos.txt";
      padding = {
        left = 1;
        right = 1;
        top = 0;
      };
    };
    display = ffDisplay;
    modules = ffModules;
  };
  # Compact: mini uwu logo + trimmed info, 9 rows, fits 61 cols / short windows.
  xdg.configFile."fastfetch/compact.jsonc".text = builtins.toJSON {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = {
      type = "file";
      source = "${config.home.homeDirectory}/.config/fastfetch/nixowos-mini.txt";
      color = {
        "1" = "38;2;82;119;195";
        "2" = "38;2;126;186;228";
        "3" = "38;2;223;144;175";
      };
      padding = {
        left = 1;
        right = 2;
        top = 0;
      };
    };
    display = ffDisplay;
    modules = ffMiniModules;
  };
  xdg.dataFile."applications/mimeapps.list".text = mimeapps;
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
