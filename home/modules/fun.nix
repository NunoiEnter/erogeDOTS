# home/modules/fun.nix
# Terminal toys (larp kit). Docs in docs/larper.md. Nothing here is load-bearing.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cava
    cmatrix
    hollywood
    pipes-rs
    tty-clock
    asciiquarium
    oneko
    cbonsai
    lolcat
    figlet
    fortune
    neo-cowsay
    pokemon-colorscripts
    sl
    chafa
    imagemagick
  ];

  programs.zsh.shellAliases = {
    cmx = "cmatrix -C \${CMATRIX_COLOR:-cyan}";
    cave = "cava -p ~/.config/cava/config";
    hwood = "hollywood";
    pipes = "pipes-rs -t $(tput cols) -r 0.5";
    ttyclock = "tty-clock -C \${CMATRIX_COLOR:-cyan} -s -g";
    aqua = "asciiquarium";
    catgo = "oneko";
    treeg = "cbonsai -l";
    rainbows = "fortune -s | cowsay | lolcat";
    pkmn = "pokemon-colorscripts -r 1 --no-title | lolcat";
    shout = "figlet -f small -c | lolcat";
    train = "sl";
  };
}
