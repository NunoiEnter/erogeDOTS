# home/modules/dev.nix
# Dev tools only. Ephemeral toolsets live in shells/, this is daily-driver set.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim
    vscodium
    go
    cargo
    rustc
    bun
    gh
    opencode
    claude-code
    codex
    gcc
    gdb
    ripgrep
    fd
    jq
    htop
    btop
    tree-sitter
  ];
}
