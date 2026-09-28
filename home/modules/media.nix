# home/modules/media.nix
# Music daemon + client. Off by default for RAM; start manually.
{ pkgs, ... }:
{
  home.packages = [ pkgs.rmpc ];

  services.mpd = {
    enable = false; # manual: systemctl --user start mpd
    musicDirectory = "/home/moni/Music";
    playlistDirectory = "/home/moni/Music/playlists";
    network = {
      listenAddress = "127.0.0.1";
      port = 6600;
    };
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Output"
      }
    '';
  };
}
