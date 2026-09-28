# hosts/NixChan/modules/power.nix
# TLP owns battery policy. performance on AC, saver on battery.
{
  services.upower.enable = true;
  services.power-profiles-daemon.enable = false;
  powerManagement.enable = true;
  services.tlp = {
    enable = true;
    pd.enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 0;
      STOP_CHARGE_THRESH_BAT0 = 100;
      TLP_AUTO_SWITCH = 1;
      TLP_PROFILE_AC = "PRF";
      TLP_PROFILE_BAT = "SAV";
    };
  };
}
