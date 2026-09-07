{ pkgs }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    python3
    python3Packages.ruff
    pyright
    uv
    python3Packages.black
    python3Packages.isort
    python3Packages.mypy
    python3Packages.pudb
  ];

  PYTHONBREAKPOINT = "pudb.set_trace";

  shellHook = ''
    echo "🐍 Python $(python3 --version | awk '{print $2}') | uv $(uv --version | awk '{print $2}')"
  '';
}
