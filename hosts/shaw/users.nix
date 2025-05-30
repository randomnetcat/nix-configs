{ config, lib, pkgs, inputs, ... }:

let
  usersDataset = "nas_oabrke/data/users";
  qenyaDataset = "${usersDataset}/qenya";
in
{
  config = {
    randomcat.services.zfs.datasets = {
      "${usersDataset}" = {
        mountpoint = "none";
      };

      "${qenyaDataset}" = {
        zfsOptions = {
          # Don't use a Nix-managed mountpoint in order to allow inheritance.
          mountpoint = "/home/qenya/data";
          quota = "2TiB";
        };

        zfsPermissions.users."${config.users.users.qenya.name}" = [
          "bookmark"
          "clone"
          "create"
          "destroy"
          "diff"
          "hold"
          "mount"
          "promote"
          "receive"
          "rename"
          "rollback"
          "send"
          "snapshot"
        ];
      };
    };

    users.users.qenya = {
      isNormalUser = true;
      group = config.users.groups.qenya.name;
      shell = pkgs.zsh;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJEmkV9arotms79lJPsLHkdzAac4eu3pYS08ym0sB/on qenya@tohru"
      ];

      extraGroups = [
        "wheel"
      ];
    };

    users.groups.qenya = { };

    programs.zsh.enable = true;

    home-manager.users.qenya.imports = [
      inputs.qenyaNixfiles.homeManagerModules."qenya"
      inputs.qenyaNixfiles.homeManagerModules."qenya@shaw"
    ];

    nix.settings.allowed-users = [
      config.users.users.qenya.name
    ];

    # Syncthing. Note that ports are one greater than defaults.
    networking.firewall = {
      allowedTCPPorts = [ 8385 22001 ];
      allowedUDPPorts = [ 21028 22001 ];
    };
  };
}
