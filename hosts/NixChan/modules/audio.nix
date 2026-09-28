# hosts/NixChan/modules/audio.nix
# PipeWire with CD + studio rates.
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    extraConfig = {
      pipewire."10-allowed-rates" = {
        "context.properties" = {
          "default.clock.allowed-rates" = [ 44100 48000 ];
        };
      };
      pipewire-pulse."10-resample-quality" = {
        "stream.properties" = {
          "resample.quality" = 4;
        };
      };
    };
  };
}
