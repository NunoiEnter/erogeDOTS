{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python312
    linuxHeaders
    gcc
    pkg-config
    # Wayland helpers pg_computer needs at runtime (install.sh skips on NixOS)
    grim
    slurp
    wl-clipboard
    ydotool
    wtype
    glib
    xdg-desktop-portal
    wlr-randr
  ];

  shellHook = ''
    export C_INCLUDE_PATH="${pkgs.linuxHeaders}/include:$C_INCLUDE_PATH"
    export NIX_CFLAGS_COMPILE="-I${pkgs.linuxHeaders}/include $NIX_CFLAGS_COMPILE"
    echo "🖥️  pg-computer shell: Python $(python3.12 --version 2>&1 | awk '{print $2}') + linuxHeaders ${pkgs.linuxHeaders.version}"
    echo "   run: bash ~/PG-COMPUTER-Linux/install.sh --no-system --register"
    echo "   uinput already configured in hosts/NixChan/configuration.nix (kernelModules + udev rule + input group)"
  '';
}
