# hosts/NixChan/modules/desktop.nix
# Compositor, fallback DEs, display manager, lock screen.
{ pkgs, inputs, ... }:
let
  # qylock shim fix: theme's isQuickshell = sddm.hostName === undefined.
  # Shim lacks hostName, so clicks guarded by !isQuickshell are dead.
  # Also lacks suspend(). Patch both.
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
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

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
    quickshell.enable = false; # using patched shim via systemPackages
  };

  environment.systemPackages = [ qylockQs ];
}
