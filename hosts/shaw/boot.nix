{ pkgs, config, lib, ... }:

let
  kernelVersion = config.boot.kernelPackages.kernel.version;

  it87Object = "${config.boot.kernelPackages.it87}/lib/modules/${kernelVersion}/kernel/drivers/hwmon/it87.ko";
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
    # the kernel-modules directly). The fist problem occurs because the in-tree
    # kernel packages are built to a compressed .ko.xz. So, when
    # aggregateModules links our modified it87 derivation into the final module
    # tree, it just links in the .ko file, leaving the .ko.xz file intact. And,
    # apparently, modprobe prefers the .ko.xz file!
    #
    # Second, even if we fix this, although the extraModulePackages *should*
    # take precedence over the in-tree modules according to the wiki, it
    # doesn't!  It instead gives an error about the conflicting file. (This is
    # implemented (in pkgs.aggregateModules, used by system.ModulesTree.) So,
    # we can't do that either.
    #
    # So, instead, we force modprobe to load our modified module instead. This
    # should be fine, since the dependency information should hopefully match
    # the built-in module.

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

    boot.kernelModules = [ "it87" ];

    boot.extraModprobeConfig = ''
      install it87 /run/current-system/sw/bin/modprobe --ignore-install ${it87Object} fix_pwm_polarity=1 $CMDLINE_OPTS
    '';

    system.checks = [
      (pkgs.runCommand "check-it87-override" {} ''
        MOD_PATH=${lib.escapeShellArg it87Object}

        if [ -f "$MOD_PATH" ]; then
          mkdir -- "$out"
        else
          echo "Path does not exist: $MOD_PATH"
          exit 1
        fi
      '')
    ];
  };
}
