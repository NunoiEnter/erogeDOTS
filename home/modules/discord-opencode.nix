{ config, lib, pkgs, discord-opencode-bot, ... }:

let
  bot = discord-opencode-bot;
  envFile = "${config.home.homeDirectory}/.config/opencode/discord-bot.env";
in
{
  home.file.".config/opencode/discord-bot.env.example".source =
    ../../pkgs/discord-opencode/discord-bot.env.example;

  home.activation.createDiscordOpencodeBotEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -e "$HOME/.config/opencode/discord-bot.env" ]]; then
      install -Dm600 "$HOME/.config/opencode/discord-bot.env.example" "$HOME/.config/opencode/discord-bot.env"
    fi
  '';

  systemd.user.services.discord-opencode-bot = {
    Unit = {
      Description = "Oko-chan Discord bridge for OpenCode";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      ConditionPathExists = envFile;
    };
    Service = {
      ExecStart = "${bot}/bin/discord-opencode-bot";
      Environment = [ "PATH=${lib.makeBinPath [ pkgs.opencode ]}" ];
      EnvironmentFile = envFile;
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      UMask = "0077";
    };
    Install.WantedBy = lib.mkForce []; # disabled for RAM, manual: systemctl --user start discord-opencode-bot
  };
}
