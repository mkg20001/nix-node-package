let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ../nix/node-package.nix { root = ../testpackage; lock = ./package-lock.json; pkgs = pkgs; };
in mkDerivation { }
