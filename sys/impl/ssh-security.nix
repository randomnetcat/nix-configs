{ ... }:

{
  config = {
    # SSH security (if enabled)
    # From https://xeiaso.net/blog/paranoid-nixos-2021-07-18
    services.openssh = {
      settings = {
        X11Forwarding = false;
        AllowTcpForwarding = false;
        AllowAgentForwarding = false;
        AllowStreamLocalForwarding = false;
        DisableForwarding = true;

        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        AuthenticationMethods = "publickey";
        PermitRootLogin = "prohibit-password";
      };
    };
  };
}
