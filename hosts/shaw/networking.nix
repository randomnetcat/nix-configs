{ ... }:

{
  config = {
    networking.useNetworkd = true;
    networking.dhcpcd.enable = false;

    systemd.network = {
      enable = true;

      networks."50-enp0s4" = {
        matchConfig.Name = "enp0s4";

        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };

        linkConfig.RequiredForOnline = "routable";
      };
    };

    # For container support
    networking.nat.enable = true;
    networking.nat.externalInterface = "enp0s4";
    networking.nat.internalInterfaces = [ "ve-+" ];
  };
}
