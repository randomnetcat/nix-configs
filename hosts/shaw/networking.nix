{ ... }:

{
  config = {
    networking.useNetworkd = true;
    networking.dhcpcd.enable = false;

    systemd.network = {
      enable = true;

      networks."50-enp4s0" = {
        matchConfig.Name = "enp4s0";

        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };

        # linkConfig.RequiredForOnline = "routable";
      };

      networks."50-enp3s0" = {
        matchConfig.Name = "enp3s0";

        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };

        # linkConfig.RequiredForOnline = "routable";
      };
    };

    # For container support
    # networking.nat.enable = true;
    # networking.nat.externalInterface = "enp0s4";
    # networking.nat.internalInterfaces = [ "ve-+" ];
  };
}
