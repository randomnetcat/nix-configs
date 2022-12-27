# NixOS Configurations

## Machines
- `groves`: Dell G15 5511, primary laptop
- `reese`: Oracle Cloud aarch64 VPS

## Laptop Manual Setup Steps

1. Add to tailscale
2. Setup remote builder access:
   * Copy in ssh private key and config (see Data)
3. Setup yubikey
   * See https://nixos.wiki/wiki/Yubikey

## Data:

root's `.ssh/config` for remote builder:
```
Host nix-builder-0-aarch64
        HostName reese
        Port 22
        User remote-build

        # Prevent using ssh-agent or another keyfile, useful for testing
        IdentitiesOnly yes
        IdentityFile /root/.ssh/nix_remote_oracle_server
```
