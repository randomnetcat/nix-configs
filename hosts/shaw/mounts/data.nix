{ config, pkgs, ... }:

{
  config = {
    environment.etc."crypttab".text = ''
      luks-data0 /dev/disk/by-uuid/dffb688d-1028-486d-a86f-fe07cae741b5 /root/keys/luks-data
      luks-data1 /dev/disk/by-uuid/faedab93-742e-4e0c-a026-110e826a91e2 /root/keys/luks-data
      luks-data2 /dev/disk/by-uuid/b991dc4f-2bae-481c-8a77-20a140d99b00 /root/keys/luks-data
      luks-data3 /dev/disk/by-uuid/d318e8f0-6aca-4115-bd9e-9840696e20f5 /root/keys/luks-data
    '';

    boot.zfs.extraPools = [
      "nas_oabrke"
    ];

    systemd.services."zfs-import-nas_oabrke" = {
      wants = [
        "systemd-cryptsetup@luks\\x2ddata0.service"
        "systemd-cryptsetup@luks\\x2ddata1.service"
        "systemd-cryptsetup@luks\\x2ddata2.service"
        "systemd-cryptsetup@luks\\x2ddata3.service"
      ];

      after = [
        "systemd-cryptsetup@luks\\x2ddata0.service"
        "systemd-cryptsetup@luks\\x2ddata1.service"
        "systemd-cryptsetup@luks\\x2ddata2.service"
        "systemd-cryptsetup@luks\\x2ddata3.service"
      ];
    };
  };
}
