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
      "https://cache.numtide.com"
      "https://cache.nixos.org/"
    ];
    trusted-substituters = [
      "https://cache.numtide.com"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWg4T3M2wMCcO6n4T0L2TNA="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
    fallback = true;
    connect-timeout = 10;
    stalled-download-timeout = 10;
    download-attempts = 5;
    http-connections = 16;
    max-substitution-jobs = 8;
    max-jobs = 4;
    cores = 2;
    min-free = "5G";
    max-free = "20G";
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # User
  users.users.moni = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "dialout" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # Antigravity CLI (agy) is provided by llm-agents.nix
  # (llmAgents.antigravity-cli) and added to home.packages in home/moni.nix.
  # nix-ld lets other unpatched prebuilt dynamic binaries run natively;
  # steam-run remains available as a fallback runner.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      glibc
      openssl
      libsecret
    ];
  };

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
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  # Desktop. Niri is primary; XFCE remains available as the fallback session.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  programs.niri = {
    enable = true;
    useNautilus = false;
  };
  services.xserver.desktopManager.xfce.enable = true;
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
  programs.dconf.enable = true;
  # LocalSend: send files to the phone over Wi-Fi (opens TCP/UDP 53317 so the phone can find this PC).
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };
  environment.systemPackages = with pkgs; [
    qylockQs
    gsettings-desktop-schemas
  ];

  # Remote desktop / screen share. The GNOME portal is the only backend here
  # that implements ScreenCast on Niri (it uses zwlr-screencopy as a fallback
  # outside GNOME). Neither xdg-desktop-portal-gtk 1.15 nor the KDE build in
  # this closure export impl.portal.ScreenCast, so Discord/Meet screen share
  # failed with "No such interface org.freedesktop.impl.portal.ScreenCast".
  # Sunshine uses KMS capture, bypasses portal, best for iPad Moonlight mirror.
  # gnome-keyring is the headless Secret Service backend for browser and Steam
  # password storage; it was previously pulled in by the GNOME desktop module.
  services.gnome.gnome-keyring.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = lib.mkForce (with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      kdePackages.xdg-desktop-portal-kde
    ]);
    config.niri = {
      default = lib.mkForce [
        "gnome"
        "gtk"
        "kde"
      ];
      # Qt6 dialog for file/folder pickers: modern look and it can actually
      # select folders, which the GTK3 portal backend cannot.
      "org.freedesktop.impl.portal.FileChooser" = lib.mkForce [ "kde" ];
      "org.freedesktop.impl.portal.Settings" = lib.mkForce [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = lib.mkForce [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = lib.mkForce [ "gnome" ];
      "org.freedesktop.impl.portal.RemoteDesktop" = lib.mkForce [ "gnome" ];
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
    wireplumber.extraConfig = {
      "10-default-targets"."wireplumber.settings" = {
        "node.restore-default-targets" = false;
      };
    };
  };
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = false;
  powerManagement.enable = true;
  services.tlp = {
    enable = true;
    pd.enable = true;
    settings = {
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
      timeoutStyle = "menu";
      splashImage = null;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
    timeout = 10;
  } else {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    configurationLimit = 10;
  };

  # Quiet boot defaults; filesystems remain hardware-specific.
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "rd.udev.log_level=3"
    "rd.systemd.show_status=auto"
    "psmouse.synaptics_intertouch=1"
  ];
  boot.extraModprobeConfig = ''
    options psmouse synaptics_intertouch=1
  '';

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
