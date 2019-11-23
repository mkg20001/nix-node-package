let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ../nix/default.nix pkgs ./. {
    nodejs = pkgs.nodejs-10_x;
  };
in mkDerivation { }
