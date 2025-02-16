{ pkgs, ... }:

{
  CodeMirror = pkgs.fetchzip {
    url = "https://web.archive.org/web/20250216191252if_/https://extdist.wmflabs.org/dist/extensions/CodeMirror-REL1_43-567fd95.tar.gz";
    sha256 = "sha256-6i4l8lj0NuxoQzpGgTaxKLA8vkhkjwQ36VpU1XRBw2w=";
  };

  DarkMode = pkgs.fetchzip {
    url = "https://web.archive.org/web/20250216192120if_/https://extdist.wmflabs.org/dist/extensions/DarkMode-REL1_43-c1b6238.tar.gz";
    sha256 = "sha256-QKPrSHb7JA3MDdCQX13bccDd0mxCJWCS8a2XGolKOys=";
  };

  MobileFrontend = pkgs.fetchzip {
    url = "https://web.archive.org/web/20250216191502if_/https://extdist.wmflabs.org/dist/extensions/MobileFrontend-REL1_43-bd01242.tar.gz";
    sha256 = "sha256-/VpjnuTmZA4W8ANhfcm7JYyLV6TTOr4t8x6Jsk3KqcE=";
  };
}
