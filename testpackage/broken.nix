with (import <nixpkgs> {});
let
  json = builtins.fromJSON(builtins.readFile ./package-lock.json);
in
  stdenv.mkDerivation({
    name = json.name;
    version = json.version;
  })
