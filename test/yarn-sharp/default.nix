let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ../../nix/default.nix pkgs {
    root = ./.;
    nodejs = pkgs.nodejs-16_x;
    build = true;
    yarnLock = ./yarn.lock;
  };
in mkDerivation (with pkgs; {
  NIX_CFLAGS_COMPILE = [
    "-I${glib.dev}/include/glib-2.0"
    "-I${glib.out}/lib/glib-2.0/include"
  ];

  buildInputs = [
    vips
    glib
    glibmm
    gobject-introspection
  ];

  nativeBuildInputs = [
    gobject-introspection
    pkg-config
  ];

})
