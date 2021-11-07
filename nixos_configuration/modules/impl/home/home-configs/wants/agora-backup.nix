{ pkgs, lib, config, ... }:

{
  options = {
    home.randomcat.agora-backup = {
      enable = lib.mkEnableOption {
        name = "Agora list backup";
      };
    };
  };

  config = lib.mkIf (config.home.randomcat.agora-backup.enable) {
    home.file."backups/agora/lists/.keep" = {
      text = "";
    };

    systemd.user.services.backup-agora-list =
      let
        agoraBackupScript = pkgs.writeShellScript "backup-agora-list" ''
          cd ~/backups/agora/lists
          ${pkgs.wget}/bin/wget -c https://agora:nomic@mailman.agoranomic.org/archives/agora-discussion.mbox
          ${pkgs.wget}/bin/wget -c https://agora:nomic@mailman.agoranomic.org/archives/agora-business.mbox
          ${pkgs.wget}/bin/wget -c https://agora:nomic@mailman.agoranomic.org/archives/agora-official.mbox
        '';
      in
      {
        Unit = {
          Description = "Automatically backup agora lists";
          After = [ "basic.target" ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${agoraBackupScript}";
        };
      };

    systemd.user.timers.backup-agora-list = {
      Install = {
        WantedBy = [ "timers.target" ];
      };

      Timer = {
        OnBootSec = "10m";
        OnUnitActiveSec = "1d";
      };
    };
  };
}
