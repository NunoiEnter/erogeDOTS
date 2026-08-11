{ pkgs }:

pkgs.mkShell {
  name = "webapp";
  packages = with pkgs; [
    bun
    gh
    nodejs
    git
  ];
}