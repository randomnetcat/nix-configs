let
  commit = "57806bf7e340f4cae705c91748d4fdf8519293a9";
  tarballPath = builtins.fetchTarball {
    url = "https://github.com/ryantm/agenix/archive/${commit}.tar.gz";
    sha256 = "1pn2k3f0qx462pgpbdhhlypyck8lwnpm3l0dbzq1y6s0v33cwwjq";
  };
in
"${tarballPath}/modules/age.nix"
