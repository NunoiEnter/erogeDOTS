{ config, pkgs, inputs, lib, ... }:

let
  # qylock quickshell shim fix: theme's isQuickshell = sddm.hostName === undefined.
  # Shim lacks hostName -> all click actions guarded by !isQuickshell are dead.
  # Also shim lacks suspend(). Patch both.
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
  imports = [ ../../modules/nixos/i18n.nix ];
  # Boot 1G fix: ESP 96M -> /efi, /boot on root ext4 (26G free) via GRUB. GRUB reads ext4, systemd-boot cannot.
  # No repartition, no Windows move, 1G+ effective. Limit 10 safe now.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true; # detect Windows
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/efi";

  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "rd.udev.log_level=3" "rd.systemd.show_status=auto" ];
  boot.loader.timeout = 5;
  networking.hostName = "NixChan";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 21115 21116 21117 21118 21119 ];
  networking.firewall.allowedUDPPorts = [ 21116 ];
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  services.tailscale.enable = true;

  # Windows Remote Desktop Connection opens a separate XFCE session.
  services.xrdp = {
    enable = true;
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
  services.sunshine.enable = false;

  services.openssh = {
    enable = true;
    # Key-only after iPad key installed: set false, rebuild.
    settings.PasswordAuthentication = true;
    settings.PermitRootLogin = "no";
  };

  time.timeZone = "Asia/Bangkok";
  i18n.defaultLocale = "en_US.UTF-8";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  programs.niri.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.desktopManager.gnome.enable = true;
  programs.zsh.enable = true;
  services.flatpak.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  programs.qylock = {
    enable = true;
    theme = "nothing";
    quickshell.enable = false;  # using patched shim via systemPackages
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    extraConfig = {
      pipewire."10-allowed-rates" = {
        "context.properties" = {
          "default.clock.allowed-rates" = [ 44100 48000 ];
        };
      };
      pipewire-pulse."10-resample-quality" = {
        "stream.properties" = {
          "resample.quality" = 4;
        };
      };
    };
  };

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  powerManagement.enable = true;

  # KMITL VPN — NetworkManager GUI (KDE system tray)
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];
  environment.systemPackages = with pkgs; [
    vim git wget firefox
    qylockQs
  ];

  # RustDesk Wayland remote input: uinput device + input group.
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  users.users.moni = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
    shell = pkgs.zsh;
  };

  # Passwordless sudo, scoped to NixOS system management only.
  # Lets the erogeDOTS agent (running as moni) rebuild, verify, and clean up
  # this machine's config without a password prompt. Everything else still
  # needs a password. Single-user desktop trade-off, accepted deliberately.
  security.sudo.extraRules = [
    {
      users = [ "moni" ];
      commands = [
        { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nix-collect-garbage"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nix-store"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nix"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      google-fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];
    fontconfig = {
      defaultFonts = {
        sansSerif = [ "Kanit" "Noto Sans" ];
        serif = [ "Kanit" "Noto Serif" ];
        monospace = [ "JetBrainsMono Nerd Font" "Fira Code" ];
      };
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (builtins.parseDrvName pkg.name).name [
    "wine" "steam" "heroic" "google-chrome"
  ];
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
    options = "--delete-older-than 7d";
  };

  system.stateVersion = "26.05"; 
}
