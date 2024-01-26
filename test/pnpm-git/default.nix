let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ../../nix/default.nix pkgs {
    root = ./.;
    pnpmLock = ./pnpm-lock.yaml;
    nodejs = pkgs.nodejs_20;
  };
in mkDerivation { }
