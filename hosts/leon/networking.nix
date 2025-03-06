{ ... }:

{
  config = {
    networking.useNetworkd = true;
    networking.dhcpcd.enable = false;

    systemd.network = {
      enable = true;

      networks."50-enp1s0" = {
        matchConfig.Name = "enp1s0";

        networkConfig = {
          DHCP = "ipv4";

          DNS = "9.9.9.9 149.112.112.122 2620:fe::fe 2620:fe::9 8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844";
          DNSDefaultRoute = true;
        };

        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
