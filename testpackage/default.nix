with (import <nixpkgs> {});
let
  json = builtins.fromJSON(builtins.readFile ./package-lock.json);
  flatTree = { name, version, requires ? {}, dependencies ? [], resolved, integrity }:
    let
      integrity = builtins.match "^([a-z0-9]+)-(.+)$" integrity;

    in
      stdenv.mkDerivation({
        name = name;
        version = version;

      });
  recurseTree = { dependencies, ... }:
    builtins.concatMap(map (dep: {
      ${dep.name} = flatTree(dep);
    }) dependencies);
  modules = recurseTree(json);
in
  stdenv.mkDerivation({
    name = json.name;
    version = json.version;
    src = "./src";
  })
