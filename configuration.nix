{ config, pkgs, ... }:

{
  # Bootloader configurations
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Network config
  networking.hostName = "NixChan"; 
  networking.networkmanager.enable = true;

  # Internationalization & Locales
  time.timeZone = "Asia/Bangkok";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "ja_JP.UTF-8/UTF-8"
    "th_TH.UTF-8/UTF-8"
  ];
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "th_TH.UTF-8";
    LC_IDENTIFICATION = "th_TH.UTF-8";
    LC_MEASUREMENT = "th_TH.UTF-8";
    LC_MONETARY = "th_TH.UTF-8";
    LC_NAME = "th_TH.UTF-8";
    LC_NUMERIC = "th_TH.UTF-8";
    LC_PAPER = "th_TH.UTF-8";
    LC_TELEPHONE = "th_TH.UTF-8";
    LC_TIME = "th_TH.UTF-8";
  };

  # Graphics Pipeline & Display Servers
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  
  # Modern hardware.graphics syntax for modern NixOS
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Display Manager & Window Manager declarations
  programs.niri.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # Keyboard configuration
  services.xserver.xkb = {
    layout = "us,th";
    options = "grp:alt_shift_toggle";
  };

  # Audio Layer (PipeWire over PulseAudio)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Shell configurations
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;

  # User Definition
  users.users.moni = {
    isNormalUser = true;
    description = "moni";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
  };

  # System-wide utilities
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    mesa-demos
    vulkan-tools
  ];

  # System options
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  services.flatpak.enable = true;
  programs.steam.enable = true;

  # Keep this matching your baseline installation version
  system.stateVersion = "26.05"; 
}
