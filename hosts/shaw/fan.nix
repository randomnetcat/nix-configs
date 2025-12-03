{ pkgs, config, lib, ... }:

{
  config = {
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
    # the kernel-modules directly). The first problem occurs because the
    # in-tree kernel packages are built to a compressed .ko.xz. So, when
    # aggregateModules links our modified it87 derivation into the final module
    # tree, it just links in the .ko file, leaving the .ko.xz file intact. And,
    # apparently, modprobe prefers the .ko.xz file!
    #
    # Second, even if we fix this, although the extraModulePackages *should*
    # take precedence over the in-tree modules according to the wiki, it
    # doesn't! It instead gives an error about the conflicting file. (This is
    # implemented (in pkgs.aggregateModules, used by system.ModulesTree.) So,
    # we can't do that either.
    #
    # So, instead, we take the approach in [0]. modprobe will prefer kernel
    # modules in the "updates" directory. So, we change the module derivation
    # to build into that directory.
    #
    # [0]: https://github.com/NixOS/nixpkgs/pull/213773

    boot.kernelPackages = pkgs.linuxPackages.extend (self: super: {
      it87 = super.it87.overrideAttrs (old: rec {
        name = "it87-${version}-${self.kernel.version}";
        version = "unstable-2023-11-11";

        src = pkgs.fetchFromGitHub {
          owner = "frankcrawford";
          repo = "it87";
          rev = "6392311da76b4868efd7b6db8101e10f9e453c75";
          sha256 = "bletkm02WDhhI9dXAPnxuS9uIr3rk4Af7GohwwSM+WQ=";
        };

        makeFlags = (lib.filter (o: !(lib.hasPrefix "MODDESTDIR=" o)) old.makeFlags) ++ [
          "MODDESTDIR=$(out)/lib/modules/${self.kernel.modDirVersion}/updates/drivers/hwmon"
          "COMPRESS_XZ=y"
        ];
      });
    });

    boot.extraModulePackages = [
      config.boot.kernelPackages.it87
    ];

    boot.kernelModules = [ "it87" ];

    boot.extraModprobeConfig = ''
      options it87 fix_pwm_polarity=1
    '';
  };
}
