# hosts/NixChan/modules/remote.nix
# Remote access. xrdp off by default for RAM. uinput stays for rustdesk/pg-computer.
{ pkgs, lib, ... }:
{
  # Windows Remote Desktop opens a separate XFCE session.
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

  # RustDesk Wayland remote input + pg-computer uinput.
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';
}
