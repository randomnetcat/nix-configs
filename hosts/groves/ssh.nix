{ config, lib, pkgs, ... }:

{
  config = {
    services.openssh = {
      enable = true;
      openFirewall = true;

      settings = {
        AuthenticationMethods = "publickey";
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
      };
    };

    users.users.randomcat = {
      openssh.authorizedKeys.keys = config.randomcat.network.users.randomcat.sshKeys;
    };
  };
}
