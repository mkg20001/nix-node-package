let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ../../nix/default.nix pkgs {
    root = ./.;
    nodejs = pkgs.nodejs-12_x;
    buildProduction = true;
  };
in mkDerivation { }
