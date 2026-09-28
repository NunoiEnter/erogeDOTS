{ pkgs }:

pkgs.mkShell {
  name = "webapp";
  nativeBuildInputs = with pkgs; [
    bun
    gh
    nodejs
    git
  ];
}