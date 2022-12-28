{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    home.packages = [ pkgs.nixopsUnstable ];

    nixpkgs.config.permittedInsecurePackages = [
      # nixpkgs thinks this is vulnerable to CVE-2022-23491, the inclusion of the
      # TrustCor root certificates.
      # nixpkgs is wrong, this version has the patch.
      "python3.10-certifi-2022.12.7"
    ];
  };
}
