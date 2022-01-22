let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ../../nix/default.nix pkgs {
    root = ./.;
    nodejs = pkgs.nodejs-16_x;
    buildProduction = true;
    yarnLock = ./yarn.lock;
  };
in mkDerivation { }
