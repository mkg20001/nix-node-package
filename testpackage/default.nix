let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ../nix/node-package.nix ".";
in mkDerivation { }
