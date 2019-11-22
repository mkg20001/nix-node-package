with (import <nixpkgs> {});
let
in
  stdenv.mkDerivation({
    name = "testpackage"; # TODO: dynamic
    version = "0.0.1"; # TODO: dynamic

    src = ./.;

    installPhase = ''
      '';
  })
