{ pkgs, lib, config, ... }:

{
  config = {
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
          Description = "Automatically backup Agora mailing lists";
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${agoraBackupScript}";
        };
      };

    systemd.user.timers.backup-agora-list = {
      Install = {
        WantedBy = [ "default.target" ];
      };

      Timer = {
        OnCalendar = "12:00:00";
        Persistent = true;
      };
    };
  };
}
