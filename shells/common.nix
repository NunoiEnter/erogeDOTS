{ pkgs }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # Version control
    git
    lazygit

    # Editors
    neovim

    # Formatters
    nixfmt-rfc-style
    shfmt
    nodePackages.prettier

    # Linters
    shellcheck

    # Utilities
    ripgrep
    fd
    jq
    yq-go
    tree
    htop
    file
    unzip
    curl
    wget
  ];

  shellHook = ''
    echo "🔧 Common dev tools loaded"
  '';
}
