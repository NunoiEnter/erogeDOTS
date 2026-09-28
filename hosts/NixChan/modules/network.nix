# hosts/NixChan/modules/network.nix
# Hostname, NetworkManager, firewall, tailscale, SSH, VPN plugin.
{ pkgs, ... }:
{
  networking.hostName = "NixChan";
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];
  networking.firewall.allowedTCPPorts = [ 22 21115 21116 21117 21118 21119 ];
  networking.firewall.allowedUDPPorts = [ 21116 ];
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  services.tailscale.enable = true;

  services.openssh = {
    enable = true;
    # Key-only after iPad key installed: set false, rebuild.
    settings.PasswordAuthentication = true;
    settings.PermitRootLogin = "no";
  };
}
