{ config, lib, pkgs, theme-picker, antigravity-cli, llmAgents, ... }:

let
  repo = "${config.home.homeDirectory}/erogeDOTS";
  nvimDesktop = pkgs.writeTextFile {
    name = "nvim-terminal.desktop";
    destination = "/share/applications/nvim-terminal.desktop";
    text = ''
      [Desktop Entry]
      Name=Neovim (Terminal)
      Exec=${pkgs.kitty}/bin/kitty -e ${pkgs.neovim}/bin/nvim %F
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
    text/plain=dev.zed.Zed.desktop
    text/x-python=dev.zed.Zed.desktop
    text/css=dev.zed.Zed.desktop
    text/javascript=dev.zed.Zed.desktop
    text/x-shellscript=dev.zed.Zed.desktop
    application/json=dev.zed.Zed.desktop
    application/xml=dev.zed.Zed.desktop
    application/x-nix=dev.zed.Zed.desktop
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

  # Cosmetic fake uptime: reads 77d 21h 20m at boot and keeps counting from there,
  # so a reboot resets to 77d 21h 20m instead of starting from zero.
  ffUptime = {
    type = "command";
    key = "Uptime";
    text = ''
      t=$(cut -d" " -f1 /proc/uptime); t=''${t%%.*}; t=$((t + 77*86400 + 21*3600 + 20*60))
      d=$((t/86400)); h=$((t%86400/3600)); m=$((t%3600/60))
      p() { if [ "$1" -eq 1 ]; then echo "$1 $2"; else echo "$1 ''${2}s"; fi; }
      printf "%s, %s, %s" "$(p $d day)" "$(p $h hour)" "$(p $m min)"
    '';
    format = "{result}";
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
    ffUptime
    {
      type = "packages";
      combined = true;
    }
    "shell"
    {
      type = "wm";
      key = "WM";
    }
    {
      type = "terminal";
      format = "kitty";
    }
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

  # Narrow info set: the big logo with shortened values, one value per line.
  # Budget: logo 44 cols + 1 padding leaves 17 cols for the value. Must fit
  # 62 cols (ghostty tiles open at 62x28) so nothing wraps.
  ffNarrowUptime = {
    type = "command";
    key = "Uptime";
    text = ''
      t=$(cut -d" " -f1 /proc/uptime); t=''${t%%.*}; t=$((t + 77*86400 + 21*3600 + 20*60))
      d=$((t/86400)); h=$((t%86400/3600))
      printf "%sd %sh" "$d" "$h"
    '';
    format = "{result}";
  };

  ffNarrowModules = [
    "title"
    "separator"
    {
      type = "os";
      format = "{name} {version-id}";
    }
    {
      type = "command";
      key = "Device";
      text = ''sed 's/^ThinkPad //' /sys/class/dmi/id/product_family'';
      format = "{result}";
    }
    {
      type = "kernel";
      format = "{release}";
    }
    ffNarrowUptime
    {
      type = "packages";
      key = "Packages";
      format = "{all}";
    }
    "shell"
    {
      type = "wm";
      key = "WM";
      format = "{pretty-name} {version}";
    }
    {
      type = "terminal";
      format = "kitty";
    }
    {
      type = "command";
      key = "CPU";
      text = ''sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -1 | sed 's/ with.*//; s/^AMD //; s/^Ryzen /R/; s/PRO //' | cut -c1-12'';
      format = "{result}";
    }
    {
      type = "command";
      key = "RAM";
      text = ''awk '/^MemTotal/{t=$2}/^MemAvailable/{a=$2}END{printf "%.0f/%.0f GiB",(t-a)/1048576,t/1048576}' /proc/meminfo'';
      format = "{result}";
    }
    {
      type = "command";
      key = "Disk";
      text = ''df -h --output=used,size / | tail -1 | awk '{s=$1;t=$2;sub("G$","",s);sub("G$","",t);printf "%s/%sG",s,t}' '';
      format = "{result}";
    }
    {
      type = "battery";
      key = "Battery";
      format = "{capacity}";
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
    ffUptime
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
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
      "$HOME/erogeDOTS/scripts"
    ];
    sessionVariables = {
      TERMINAL = "kitty";
      EDITOR = "zed";
      VISUAL = "zed";
      EROGEDOTS_ROOT = repo;
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
    };

    packages = (with pkgs; [
      # Terminals and shell tools
      ghostty kitty alacritty vim git wget curl gnutar yazi fzf fetch fastfetch eza

      # Desktop
      quickshell fuzzel awww swaynotificationcenter libnotify
      xwayland-satellite upower brightnessctl playerctl wl-clipboard cliphist
      grim slurp swappy wlogout wlsunset swaylock kdePackages.kdenlive

      # Applications
      google-chrome vesktop kdePackages.dolphin kdePackages.ark
      qimgv vlc mpv yt-dlp ytui-music qbittorrent p7zip unrar
      foliate figma-linux zed-editor arduino-ide arduino-cli tree discord
      discordo

      # AI agents: llm-agents.nix builds (daily), not nixpkgs / local FHS
      llmAgents.chatgpt
      llmAgents.claude-desktop
      llmAgents.codex
      llmAgents.claude-code
      llmAgents.opencode

      # Development
      neovim vscodium go cargo rustc bun gh gcc gdb
      ripgrep fd jq htop btop tree-sitter sqlite
      antigravity-cli
      pkgs.antigravity-ide

      # Gaming and media
      wine steam steam-run heroic rmpc ani-cli

      # Terminal toys
      cava cmatrix hollywood pipes-rs tty-clock asciiquarium oneko cbonsai
      lolcat figlet fortune neo-cowsay pokemon-colorscripts sl chafa imagemagick

      nvimDesktop
      theme-picker
    ]) ++ map (name: lib.getAttrFromPath (lib.splitString "." name) pkgs)
      (builtins.fromJSON (builtins.readFile ./desktop-packages.json));

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
        # Wayland subsurface compositor causes fractional scale overflow with wp_viewport;
        # disabling it keeps WebRender acceleration while using the main Wayland surface.
        "gfx.webrender.compositor" = false;
        "gfx.webrender.compositor.force-enabled" = false;
        "apz.allow_zooming" = true;
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
      setopt COMBINING_CHARS
      PROMPT='%F{magenta}%m%f %F{white}%~%%f '
      [[ -f "$HOME/.config/theme/env" ]] && source "$HOME/.config/theme/env"
      # ts wrapper: switch theme, then reload theme vars in THIS shell.
      # (A script can't touch its parent shell, so `source` must live here.)
      ts() {
        theme-switch "$@" && source "$HOME/.config/theme/env"
      }
      autoload -Uz add-zsh-hook compinit
      # Title lock: Electron apps (Claude desktop/cowork) push their whole argv
      # into OSC 0, and VS Code then shows that junk as the terminal name.
      # Re-assert ours before every command and at every prompt so nothing
      # survives. OSC 0 sets icon name + window title in kitty, ghostty, foot
      # and VS Code alike.
      _eroge_title() { printf '\e]0;%s\a' "''${TERMINAL:-kitty}"; }
      add-zsh-hook preexec _eroge_title
      add-zsh-hook precmd _eroge_title
      _eroge_title
      # Deferred shell init: runs on first prompt (after fetch paints),
      # so window animation + fetch appear together. Split hooks: slow compinit
      # can never cancel the fast plugins, even with Ctrl-C.
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
      # Live theme-matched fetch. Runs fastfetch every time so uptime/memory/disk
      # are current; the old output cache made every new shell show stale stats.
      _eroge_fetch() {
        local cfg="$1" k tg l1 l2 l3
        local -a flags
        k="''${THEME_PRIMARY:-#ff8fb1}"; tg="''${THEME_FG:-#c0caf5}"
        l1="''${THEME_PRIMARY_DARK:-#5277c3}"; l2="''${THEME_PRIMARY:-#7ebae4}"; l3="''${THEME_PRIMARY_LIGHT:-#df90af}"
        flags=(--pipe false --color-keys "$k" --color-title "$tg" --logo-color-1 "$l1" --logo-color-2 "$l2" --logo-color-3 "$l3" --logo-color-4 "$l1" --logo-color-5 "$l3")
        if [[ -n "$cfg" ]]; then flags+=(-c "$cfg"); fi
        fastfetch "''${flags[@]}"
      }
      clear() {
        command clear "$@"
        [[ "''${EROGEDOTS_NO_FASTFETCH:-0}" != 1 ]] && _eroge_fetch "" half
      }
      # Always the half-scale NixOwOS logo. No size gate: the compact/narrow tiers
      # only ever made large windows show the small art, and any gate at all
      # meant a small window showed nothing instead of the real logo.
      if [[ "''${EROGEDOTS_NO_FASTFETCH:-0}" != 1 ]]; then
        _eroge_fetch "" half
      fi
    '';
  };

  xdg.configFile."mimeapps.list" = {
    text = mimeapps;
    force = true;
  };
# NixOwOS branding: uwu logo (ascii by u/ant-arctica via yunfachi/NixOwOS,
  # CC-BY-4.0). The startup logo is the half-scale nixowos-half.txt, a 2x
  # downsample of nixowos.txt: block glyphs carry 2x2 sub-pixels, so sampling
  # every other cell keeps the drawing at half width and height.
  # File logos, no fastfetch overlay rebuild. Drops noisy Unknown modules
  # (de/wmtheme/theme/icons/font/terminalfont/swap/localip/poweradapter), compact display + circle colors.
  xdg.configFile."fastfetch/nixowos.txt".source = ../config/fastfetch/nixowos.txt;
  xdg.configFile."fastfetch/nixowos-half.txt".source = ../config/fastfetch/nixowos-half.txt;
  xdg.configFile."fastfetch/nixowos-mini.txt".source = ../config/fastfetch/nixowos-mini.txt;
  xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = {
      type = "file";
      source = "${config.home.homeDirectory}/.config/fastfetch/nixowos-half.txt";
      padding = {
        left = 0;
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
  # Narrow: big uwu logo + short values on the right, fits 62 cols x 21 rows
  # (ghostty's default tiled windows are 62x28). Same logo as the full config.
  xdg.configFile."fastfetch/narrow.jsonc".text = builtins.toJSON {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = {
      type = "file";
      source = "${config.home.homeDirectory}/.config/fastfetch/nixowos.txt";
      padding = {
        left = 0;
        right = 1;
        top = 0;
      };
    };
    display = ffDisplay;
    modules = ffNarrowModules;
  };
  # GLib always searches ~/.local/share/glib-2.0/schemas, and a NixOS system
  # profile cannot merge the share/gsettings-schemas package layout. Link the
  # compiled GNOME schemas so gsettings works for every process of this user.
  xdg.dataFile."glib-2.0/schemas".source =
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
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
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    playlistDirectory = "${config.home.homeDirectory}/Music/playlists";
    network = {
      listenAddress = "127.0.0.1";
      port = 6600;
    };
    extraConfig = ''
      auto_update "yes"
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
