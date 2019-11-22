with (import <nixpkgs> {});
let
  root = ./.;

  json = builtins.fromJSON(builtins.readFile "${root}/package-lock.json");
in
  stdenv.mkDerivation({
    name = json.name; # TODO: dynamic
    version = json.version; # TODO: dynamic

    src = ./.;

    installPhase = ''
      ls
      '';
  })
