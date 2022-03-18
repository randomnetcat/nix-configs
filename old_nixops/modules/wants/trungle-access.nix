{ lib, config, ... }:

{
  options = {
    features.trungle-access.enable = lib.mkEnableOption "Trungle server access";
  };

  config = lib.mkIf (config.features.trungle-access.enable) {
    users.users.trungle = {
      isNormalUser = true;
      group = "trungle";

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA57legzdIcYTVVri4Wc0CvgWefbRhmUqhu0F/5f8FB reuben@glenda-artix"
      ];
    };

    users.groups.trungle = {};

    # Open a port for Trungle to play with
    networking.firewall = {
      allowedUDPPorts = [ 6436 ];
      allowedTCPPorts = [ 6436 ];
    };
  };
}
