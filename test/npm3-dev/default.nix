let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ../../nix/default.nix pkgs {
    root = ./.;
    packageLock = ./package-lock.json;
    nodejs = pkgs.nodejs-18_x;
    buildProduction = true;
  };
in mkDerivation {
  nodeBuildPhase = ''
    mkdir -p $out
    cat $lockfile | jq > $out/da.json
    exit 0
  '';
}
