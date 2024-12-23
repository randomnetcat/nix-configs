{ ... }:

{
  nix.buildMachines = [{
    hostName = "nix-builder-0-aarch64";
    system = "aarch64-linux";
    maxJobs = 2;
    speedFactor = 2;
    supportedFeatures = [ ];
    mandatoryFeatures = [ ];
  }];
}
