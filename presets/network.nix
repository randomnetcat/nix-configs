{ config, lib, pkgs, ... }:

{
  imports = [
    ../network
  ];

  config = {
    programs.ssh.knownHosts = lib.concatMapAttrs
      (_: host: {
        "${host.hostName}".publicKey = host.hostKey;
        "${host.tailscaleIP4}".publicKey = host.hostKey;
        "${host.tailscaleIP6}".publicKey = host.hostKey;
      })
      (lib.filterAttrs (_: v: v.hostKey != null) config.randomcat.network.hosts);
  };
}
