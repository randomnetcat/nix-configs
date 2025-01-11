{ config, pkgs, ... }:

{
  config = {
    environment.etc."crypttab".text = ''
      luks-data0 /dev/disk/by-uuid/144cd1af-113a-40df-b19b-4de70e16f7db /root/keys/luks-data nofail,timeout=15
      luks-data1 /dev/disk/by-uuid/4bfa4fb7-606d-493d-aaf8-c6f34ee4e6e8 /root/keys/luks-data nofail,timeout=15
      luks-data2 /dev/disk/by-uuid/b991dc4f-2bae-481c-8a77-20a140d99b00 /root/keys/luks-data nofail,timeout=15
      luks-data3 /dev/disk/by-uuid/d318e8f0-6aca-4115-bd9e-9840696e20f5 /root/keys/luks-data nofail,timeout=15
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
