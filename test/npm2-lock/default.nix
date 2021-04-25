let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ../../nix/default.nix pkgs {
    root = ./.;
    packageLock = ./package-lock.json;
    nodejs = pkgs.nodejs-16_x;
    buildProduction = true;
  };
in mkDerivation { }
