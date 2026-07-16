{ pkgs }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    python3
    python3Packages.ruff
    python3Packages.pyright
    uv
    python3Packages.black
    python3Packages.isort
    python3Packages.mypy
  ];

  PYTHONBREAKPOINT = "pkgs.python3Packages.pudb";

  shellHook = ''
    echo "🐍 Python $(python3 --version | awk '{print $2}') | uv $(uv --version | awk '{print $2}')"
  '';
}
