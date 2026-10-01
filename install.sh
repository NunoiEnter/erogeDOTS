#!/usr/bin/env bash
# erogeDOTS ALPHA 2.0 — unattended installer after git clone
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
EXPECTED_ROOT="$HOME/erogeDOTS"
HOST_NAME="$(hostnamectl --static 2>/dev/null || hostname)"
HOST_DIR="$REPO_ROOT/hosts/$HOST_NAME"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/erogedots"
LOG_FILE="$STATE_DIR/install.log"
NEW_HOST=false
TEMP_HARDWARE=""

mkdir -p "$STATE_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

cleanup() {
    [[ -z "$TEMP_HARDWARE" ]] || rm -f -- "$TEMP_HARDWARE"
}
trap cleanup EXIT

die() {
    echo "error: $*" >&2
    exit 1
}

step() {
    echo
    echo "==> $*"
}

[[ "${EUID}" -ne 0 ]] || die "run as your normal user, not root"
[[ "$(id -un)" == "moni" ]] || die "this personal config requires user: moni"
[[ "$REPO_ROOT" == "$EXPECTED_ROOT" ]] ||
    die "clone this repository at: $EXPECTED_ROOT"
[[ -f /etc/NIXOS ]] || die "this installer requires NixOS"
[[ "$HOST_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9-]{0,62}$ ]] ||
    die "invalid hostname: $HOST_NAME"

for command_name in git nix sudo hostnamectl nixos-rebuild nixos-generate-config; do
    command -v "$command_name" >/dev/null || die "missing command: $command_name"
done

[[ -f "$REPO_ROOT/flake.nix" ]] || die "flake.nix not found"
[[ -f "$REPO_ROOT/configuration.nix" ]] || die "configuration.nix not found"

step "Authenticate sudo once"
sudo -v

if [[ ! -d "$HOST_DIR" ]]; then
    [[ -d /sys/firmware/efi ]] ||
        die "automatic new-host setup currently requires UEFI"

    step "Create host $HOST_NAME"
    mkdir -p "$HOST_DIR"
    NEW_HOST=true
fi

if [[ ! -f "$HOST_DIR/hardware-configuration.nix" ]]; then
    step "Generate hardware configuration"
    TEMP_HARDWARE="$(mktemp)"
    sudo nixos-generate-config --show-hardware-config > "$TEMP_HARDWARE"
    install -m 0644 "$TEMP_HARDWARE" "$HOST_DIR/hardware-configuration.nix"
fi

step "Check flake"
nix flake check "path:$REPO_ROOT" --no-build --no-write-lock-file

step "Build $HOST_NAME"
sudo nixos-rebuild build --flake "path:$REPO_ROOT#$HOST_NAME"

step "Activate $HOST_NAME"
sudo nixos-rebuild switch --flake "path:$REPO_ROOT#$HOST_NAME"

step "Generate active theme"
active_theme="$(cat "$HOME/.config/theme/active" 2>/dev/null || printf harumi)"
EROGEDOTS_ROOT="$REPO_ROOT" EROGEDOTS_NO_RESTART=1 \
    "$REPO_ROOT/scripts/theme-switch" "$active_theme"

step "Verify"
[[ "$(hostnamectl --static)" == "$HOST_NAME" ]] ||
    die "hostname verification failed"
[[ -e /run/current-system ]] || die "current system generation missing"
command -v theme-picker >/dev/null || die "theme-picker missing after activation"

echo
echo "ALPHA 2.0 installed successfully on $HOST_NAME"
echo "Log: $LOG_FILE"
if [[ "$NEW_HOST" == true ]]; then
    echo "New hardware file created: $HOST_DIR/hardware-configuration.nix"
    echo "Review and commit it when ready."
fi
