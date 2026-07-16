{ pkgs }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # Unit / Integration testing
    python3
    python3Packages.pytest
    python3Packages.pytest-html
    python3Packages.pytest-xdist
    python3Packages.pytest-cov
    python3Packages.requests
    python3Packages.httpx

    # API testing
    curl
    httpie
    jq

    # Load / Performance testing
    k6
    wrk
    vegeta

    # Browser automation
    nodejs
    nodePackages.pnpm
    playwright-driver
    chromium

    # Mobile / Device testing
    adb-cli

    # Coverage & Reports
    lcov
    python3Packages.coverage

    # Mocking
    python3Packages.responses
    python3Packages.pytest-mock

    # Utilities
    tree-sitter
    ripgrep
    fd
    jq
  ];

  shellHook = ''
    echo "🧪 Tester Shell loaded"
    echo "   pytest | playwright | k6 | httpie | vegeta"
  '';
}
