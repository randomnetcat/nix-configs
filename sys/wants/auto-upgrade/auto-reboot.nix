{ ... }:

{
  imports = [
    ../../impl/auto-upgrade-common.nix
  ];

  config = {
    system.autoUpgrade = {
      operation = "switch";
      allowReboot = true;
    };
  };
}
