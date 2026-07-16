{ pkgs }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    go
    gopls
    gofumpt
    golangci-lint
    gotools
    go-tools
    govulncheck
    air
  ];

  GOPATH = "$HOME/go";
  GOBIN = "$HOME/go/bin";

  shellHook = ''
    echo "🐹 Go $(go version | awk '{print $3}') | gopls $(gopls version 2>/dev/null | awk '{print $1}')"
  '';
}
