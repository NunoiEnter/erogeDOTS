#!/usr/bin/env bash
# erogeDOTS ALPHA 2.1 — visual novel installer, with a plain unattended mode
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-}" in
    --plain) ;;
    --help|-h) printf 'Usage: ./install.sh [--plain]\nInteractive VN installer on a terminal; --plain keeps the unattended workflow.\n'; exit 0 ;;
    "")
        if [[ -t 0 && -t 1 ]]; then
            if command -v theme-picker >/dev/null && theme-picker help | grep -q 'install'; then
                exec theme-picker install
            fi
            exec nix run "$REPO_ROOT#theme-picker" -- install
        fi ;;
    *) printf 'Unknown installer option: %s\n' "$1" >&2; exit 2 ;;
esac
EXPECTED_ROOT="$HOME/erogeDOTS"
HOST_NAME="$(hostnamectl --static 2>/dev/null || hostname)"
HOST_DIR="$REPO_ROOT/hosts/$HOST_NAME"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/erogedots"
LOG_FILE="$STATE_DIR/install.log"
NEW_HOST=false
TEMP_HARDWARE=""
BUILD_STAGE=""
SUDO_KEEPALIVE=""

mkdir -p "$STATE_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

cleanup() {
    [[ -z "$TEMP_HARDWARE" ]] || rm -f -- "$TEMP_HARDWARE"
    [[ -z "$BUILD_STAGE" ]] || rm -rf -- "$BUILD_STAGE"
    [[ -z "$SUDO_KEEPALIVE" ]] || kill "$SUDO_KEEPALIVE" 2>/dev/null || true
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
[[ -f /etc/NIXOS || -f /run/current-system/nixos-version ]] || die "this installer requires NixOS"
[[ "$HOST_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9-]{0,62}$ ]] ||
    die "invalid hostname: $HOST_NAME"

for command_name in git nix sudo hostnamectl nixos-rebuild nixos-generate-config; do
    command -v "$command_name" >/dev/null || die "missing command: $command_name"
done

[[ -f "$REPO_ROOT/flake.nix" ]] || die "flake.nix not found"
[[ -f "$REPO_ROOT/configuration.nix" ]] || die "configuration.nix not found"

step "Authenticate sudo once"
if [[ "${EROGEDOTS_SUDO_READY:-0}" == 1 ]]; then sudo -n -v; else sudo -v; fi
# Keep the authenticated worker usable through a long first build.
(while sleep 50; do sudo -n -v || exit; done) </dev/null >/dev/null 2>&1 &
SUDO_KEEPALIVE="$!"

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
    # The normal user owns this temporary file; only hardware discovery needs sudo.
    # shellcheck disable=SC2024
    sudo nixos-generate-config --show-hardware-config > "$TEMP_HARDWARE"
    install -m 0644 "$TEMP_HARDWARE" "$HOST_DIR/hardware-configuration.nix"
fi

step "Prepare source"
BUILD_STAGE="$(mktemp -d -t erogedots-install-XXXXXX)"
while IFS= read -r -d '' source_file; do
    [[ -f "$REPO_ROOT/$source_file" ]] || continue
    mkdir -p -- "$BUILD_STAGE/$(dirname -- "$source_file")"
    cp -p -- "$REPO_ROOT/$source_file" "$BUILD_STAGE/$source_file"
done < <(git -C "$REPO_ROOT" ls-files --cached --others --exclude-standard -z)

step "Check flake"
nix flake check "path:$BUILD_STAGE" --no-build --no-write-lock-file

step "Build $HOST_NAME"
sudo nixos-rebuild build --flake "path:$BUILD_STAGE#$HOST_NAME"

step "Activate $HOST_NAME"
sudo nixos-rebuild switch --flake "path:$BUILD_STAGE#$HOST_NAME"

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
echo "ALPHA 2.1 installed successfully on $HOST_NAME"
echo "Log: $LOG_FILE"
if [[ "$NEW_HOST" == true ]]; then
    echo "New hardware file created: $HOST_DIR/hardware-configuration.nix"
    echo "Review and commit it when ready."
fi
