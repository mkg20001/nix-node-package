let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ./autotools.nix pkgs;
  nodePackage = import ../nix/node-package.nix ".";
in mkDerivation {
  inherit nodePackage;
}
