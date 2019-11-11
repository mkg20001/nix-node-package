let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ../nix/node-package.nix { root = "."; pkgs = pkgs; };
in mkDerivation { }
