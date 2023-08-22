{ ... }:

{
  imports = [
    ../../impl/auto-upgrade-common.nix
  ];

  config = {
    system.autoUpgrade = {
      operation = "boot";
      allowReboot = false;
    };
  };
}
