{ pkgs, config, lib, ... }:

let
  kernelVersion = config.boot.kernelPackages.kernel.version;
in 
{
  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.grub.enable = false;

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.generationsDir.copyKernels = true;

    boot.loader.systemd-boot.editor = false;
    boot.loader.efi.efiSysMountPoint = "/boot";

    # Okay, this is *incredibly* stupid.
    # 
    # The kernel includes a builtin it87 module, but it's too old, and we can't
    # use it. We can, however, use a modified version of the module maintained
    # in a GitHub repo. nixpkgs includes a derivation that builds from that
    # fork, but that's *also* too old, and we can't use it. So, use the latest
    # commit of the fork (as of time of writing).
    #
    # For laziness, we just override the existing derivation. However, the
    # nixpkgs it87 derivation builds the kernel module into a .ko file. This
    # causes a problem when nixpkgs builds the final module tree (what becomes
    # the kernel-modules directly). Although the extraModulePackages *should*
    # take precedence over the in-tree modules, this is implemented (in
    # pkgs.aggregateModules, used by system.ModulesTree) by just linking in the
    # files from the extraModulePackages after. The problem occurs because the
    # in-tree kernel packages are built to a compressed .ko.xz. So, when
    # aggregateModules links our modified it87 derivation into the final module
    # tree, it just links in the .ko file, leaving the .ko.xz file intact. And,
    # apparently, modprobe prefers the .ko.xz file!
    #
    # So, we have a few options. One person
    # (https://discourse.nixos.org/t/best-way-to-handle-boot-extramodulepackages-kernel-module-conflict/30729)
    # disabled the in-tree it87 module, which does work. However, it modifies
    # the kernel derivation, so if we did that we could no longer use the
    # binary caches.
    #
    # Instead, we build the modified it87 module, then move the built result
    # compress the module to an xz file, so that it does actually take
    # precedence.  In order to ensure this is resilient against changes in
    # format, we add a check to ensure that it is actually overriding a module
    # in the base kernel.

    boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages.extend (self: super: {
      it87 = super.it87.overrideAttrs (old: rec {
        name = "it87-${version}-${self.kernel.version}";
        version = "unstable-2023-11-11";

        src = pkgs.fetchFromGitHub {
          owner = "frankcrawford";
          repo = "it87";
          rev = "6392311da76b4868efd7b6db8101e10f9e453c75";
          sha256 = "bletkm02WDhhI9dXAPnxuS9uIr3rk4Af7GohwwSM+WQ=";
        };
      });
    });

    boot.extraModulePackages = [
      (config.boot.kernelPackages.it87.overrideAttrs (old: {
        fixupPhase = ''
          ${old.fixupPhase or ""}

          xz -- "$out"/${lib.escapeShellArg "lib/modules/${kernelVersion}/kernel/drivers/hwmon/it87.ko"}

          # Move the output to the extra directory so that it takes precedence
          # over the built-in module.
          mv -- "$out"/${lib.escapeShellArg "lib/modules/${kernelVersion}/kernel"} "$out"/${lib.escapeShellArg "lib/modules/${kernelVersion}/extra"}
        '';
      }))
    ];

    # Check that it87 module exists as expected in base kernel.
    system.checks = [
      (pkgs.runCommand "check-it87-override" {} ''
        MOD_PATH=${lib.escapeShellArg "${config.boot.kernelPackages.kernel}/lib/modules/${kernelVersion}/kernel/drivers/hwmon/it87.ko.xz"}

        if [ -f "$MOD_PATH" ]; then
          mkdir -- "$out"
        else
          echo "Path does not exist: $MOD_PATH"
          exit 1
        fi
      '')
    ];

    boot.kernelModules = [ "it87" ];

    # Required per https://gist.github.com/johndavisnz/bae122274fc6f0e006fdf0bc92fe6237 (part 3)
    boot.extraModprobeConfig = ''
      options it87 fix_pwm_polarity=1
    '';
  };
}
