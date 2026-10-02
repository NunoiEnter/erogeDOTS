{ hostName, inputs, lib, pkgs, ... }:

let
  qylockQs = (inputs.qylock.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mkQuickshell {
    defaultTheme = "nothing";
  }).overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      substituteInPlace "$out/share/qylock/shim/SddmShim.qml" \
        --replace-fail \
          '        signal loginSucceeded()' \
          '        signal loginSucceeded()
        property string hostName: "qylock"' \
        --replace-fail \
          '        function reboot()' \
          '        function suspend() { Quickshell.execDetached(["bash", "-c", "if [ -d /run/systemd/system ]; then systemctl suspend; else loginctl suspend; fi"]); }
        function reboot()'
    '';
  });
in
{
  networking.hostName = hostName;

  # Nix and packages
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = lib.mkForce [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cachix.cachix.org"
    ];
    trusted-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cachix.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWg4T3M2wMCcO6n4T0L2TNA="
    ];
    fallback = true;
    connect-timeout = 15;
    stalled-download-timeout = 30;
    download-attempts = 3;
    http-connections = 8;
    max-substitution-jobs = 4;
    max-jobs = "auto";
    cores = 0;
    min-free = "5G";
    max-free = "20G";
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  # User
  users.users.moni = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "dialout" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # Network and remote access. Credentials stay outside this repository.
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];
  networking.firewall = {
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];
  };
  services.tailscale.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  services.xrdp = {
    enable = lib.mkDefault false;
    openFirewall = true;
    defaultWindowManager = ''
      unset DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY
      export XDG_SESSION_TYPE=x11
      export XDG_CURRENT_DESKTOP=XFCE
      export XDG_SESSION_DESKTOP=xfce
      exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.xfce4-session}/bin/xfce4-session
    '';
  };
  security.pam.services.xrdp-sesman.allowNullPassword = lib.mkForce false;
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  # Desktop. Niri is primary; GNOME and XFCE remain available as fallbacks.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  programs.niri.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.desktopManager.gnome.enable = true;
  services.flatpak.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  programs.qylock = {
    enable = true;
    theme = "nothing";
    quickshell.enable = false;
  };
  environment.systemPackages = [ qylockQs ];

  # Remote desktop / screen share. Niri needs GNOME portal for PipeWire share.
  # Sunshine uses KMS capture, bypasses portal, best for iPad Moonlight mirror.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };
  };
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Audio, Bluetooth and power
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    extraConfig = {
      pipewire."10-allowed-rates"."context.properties"."default.clock.allowed-rates" = [ 44100 48000 ];
      pipewire-pulse."10-resample-quality"."stream.properties"."resample.quality" = 4;
    };
  };
  hardware.bluetooth = {
    enable = false;
    powerOnBoot = false;
  };
  services.blueman.enable = false;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = false;
  powerManagement.enable = true;
  services.tlp = {
    enable = true;
    pd.enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 0;
      STOP_CHARGE_THRESH_BAT0 = 100;
      TLP_AUTO_SWITCH = 1;
      TLP_PROFILE_AC = "PRF";
      TLP_PROFILE_BAT = "SAV";
    };
  };

  # Locale and input
  time.timeZone = "Asia/Bangkok";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
    fcitx5.settings.inputMethod = {
      GroupOrder."0" = "Default";
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "us";
        DefaultIM = "keyboard-us";
      };
      "Groups/0/Items/0".Name = "keyboard-us";
      "Groups/0/Items/1".Name = "mozc";
      "Groups/0/Items/2".Name = "keyboard-th";
    };
    fcitx5.settings.globalOptions.Hotkey = {
      TriggerKeys = "Control+space Alt+Shift_L";
      EnumerateWithTriggerKeys = "True";
    };
  };
  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
  };

  # Fonts and gaming
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      google-fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ "Kanit" "Noto Sans" ];
      serif = [ "Kanit" "Noto Serif" ];
      monospace = [ "JetBrainsMono Nerd Font" "Fira Code" ];
    };
  };
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # NixChan has a tiny ESP mounted at /efi. Other hosts use normal UEFI defaults.
  boot.loader = if hostName == "NixChan" then {
    systemd-boot.enable = lib.mkForce false;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      configurationLimit = 10;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
    timeout = 0;
  } else {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    configurationLimit = 10;
  };

  # Quiet boot defaults; filesystems remain hardware-specific.
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "rd.udev.log_level=3" "rd.systemd.show_status=auto" ];

  # Distro branding (NixOwOS-style): shown in /etc/os-release, hostnamectl, fastfetch OS line.
  # ID_LIKE=nixos keeps scripts that check for NixOS working.
  system.nixos = {
    distroId = "nixowos";
    distroName = "NixOwOS";
    vendorId = "nixowos";
    vendorName = "NixOwOS";
    extraOSReleaseArgs.ID_LIKE = "nixos";
  };

  system.stateVersion = "26.05";
}
