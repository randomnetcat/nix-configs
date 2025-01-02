{ config, lib, pkgs, inputs, ... }:

{
  config = {
    birdsong.peering = {
      enable = true;
      privateKeyCredential = "wireguard-birdsong-key";
      persistentKeepalive = 23;
    };

    environment.systemPackages = [
      pkgs.wireguard-tools
    ];

    systemd.services.systemd-networkd = {
      serviceConfig = {
        LoadCredentialEncrypted = [
          "wireguard-birdsong-key:${./secrets/wireguard-birdsong-key}"
        ];
      };
    };
  };
}
