{ config, lib, pkgs, ... }:

{
  imports = [
    ../network
  ];

  config = {
    programs.ssh.knownHosts =
      lib.mkMerge (lib.mapAttrsToList
        (name: host: {
          "randomcat-${name}" = {
            publicKey = host.hostKey;

            hostNames = [
              host.hostName
              host.tailscaleIP4
              host.tailscaleIP6
            ];
          };
        })
        (lib.filterAttrs (_: v: v.hostKey != null) config.randomcat.network.hosts));
  };
}
