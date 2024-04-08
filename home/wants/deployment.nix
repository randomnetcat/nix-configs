{ pkgs, inputs, ... }:

{
  config = {
    home.packages = [
      (pkgs.extend inputs.deploy-rs.overlays.default).deploy-rs.deploy-rs
    ];
  };
}
