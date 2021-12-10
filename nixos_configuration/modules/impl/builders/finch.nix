{ ... }:

{
  nix.buildMachines = [ {
    hostName = "finch";
    system = "aarch64-linux";
    maxJobs = 2;
    speedFactor = 2;
    supportedFeatures = [ ];
    mandatoryFeatures = [ ];
  }];
}
