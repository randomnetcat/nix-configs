{ config, pkgs, ... }:

{
  config = {
    etc."crypttab".text = ''
      luks-data0 /dev/disk/by-uuid/dffb688d-1028-486d-a86f-fe07cae741b5 /root/keys/luks-data
      luks-data1 /dev/disk/by-uuid/faedab93-742e-4e0c-a026-110e826a91e2 /root/keys/luks-data
    '';
  };
}
