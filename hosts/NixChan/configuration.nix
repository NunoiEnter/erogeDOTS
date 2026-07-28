{ config, pkgs, ... }:

{
  imports = [ ../../modules/nixos/i18n.nix ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "rd.udev.log_level=3" "rd.systemd.show_status=auto" ];
  boot.loader.timeout = 5;
  networking.hostName = "NixChan";
  networking.networkmanager.enable = true;

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
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.upower.enable = true;
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";

  # MPD for rmpc music player
  services.mpd = {
    enable = true;
    settings = {
      music_directory = "/home/moni/Music";
      playlist_directory = "/home/moni/Music/playlists";
      audio_output = [
        { type = "pipewire"; name = "PipeWire Output"; }
        { type = "pulse"; name = "PulseAudio Output"; }
      ];
      bind_to_address = "127.0.0.1";
      port = 6600;
    };
  };

  # KMITL VPN — NetworkManager GUI (KDE system tray)
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];
  environment.systemPackages = with pkgs; [ vim git wget firefox ];

  users.users.moni = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    shell = pkgs.zsh;
  };

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
    "wine" "steam" "heroic"
  ];
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cachix.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWg4T3M2wMCcO6n4T0L2TNA="
    ];
    max-jobs = "auto";
    cores = 0;
    min-free = 1024;
    max-free = 2048;
  };

  system.stateVersion = "26.05"; 
}
