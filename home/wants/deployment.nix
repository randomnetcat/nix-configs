{ pkgs, inputs, ... }:

{
  config = {
    home.packages = [
      (pkgs.extend inputs.deploy-rs.overlay).deploy-rs.deploy-rs
    ];
  };
}
