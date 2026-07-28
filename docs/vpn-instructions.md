# KMITL VPN Setup

## Quick connect
```bash
# Import
nmcli connection import type openvpn file ~/Downloads/ITKMITL-FULL-TUNNEL.ovpn

# Save username/password (optional, avoids prompt)
nmcli connection modify ITKMITL-FULL-TUNNEL vpn.user-name "your_username"
nmcli connection modify ITKMITL-FULL-TUNNEL +vpn.data "password-flags=0"
nmcli connection modify ITKMITL-FULL-TUNNEL vpn.secrets "password=your_password"

# Connect
nmcli connection up ITKMITL-FULL-TUNNEL

# Disconnect
nmcli connection down ITKMITL-FULL-TUNNEL

# Status
nmcli connection show --active | grep vpn
```

## KDE GUI (no terminal)
1. Click network icon (system tray) → Settings → Connections
2. Add Connection → Import VPN Connection
3. Select `.ovpn` file
4. Enter username/password
5. Toggle on/off from system tray

## Requirements
- `networkmanager-openvpn` plugin (already in flake config)
- `.ovpn` profile from IT support

## Split vs Full Tunnel
| Profile | Use case |
|---------|----------|
| Split Tunnel | Daily use — only internal traffic via VPN |
| Full Tunnel | Research databases (IEEE Xplore etc.) |

Test: visit https://login.it.kmitl.ac.th
