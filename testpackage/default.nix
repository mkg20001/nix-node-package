with (import <nixpkgs> {});
let
  json = builtins.fromJSON(builtins.readFile ./package-lock.json);
#  flatTree = { name, version, requires ? {}, dependencies ? [], resolved, integrity }:
#    let
#      hash = builtins.match "^([a-z0-9]+)-(.+)$" integrity;
#    in
#      stdenv.mkDerivation({
#        name = name;
#        version = version;
#        src = fetchurl {
#          url = resolved;
#          ${hash[0]} = hash[1];
#        };
#      });
#  recurseTree = { dependencies, ... }:
#    builtins.concatMap(map (dep: {
#      ${dep.name} = flatTree(dep);
#    }) dependencies);
#  modules = recurseTree(json);
  recursePureEntry = { dependencies, ... }:
    builtins.concatMap (map (dep: { ${dep.name} = makePureModule(dep); }) dependencies);
  makePureModule = { name, version, requires ? {}, dependencies ? [], resolved, integrity }:
    let
      hash = builtins.match "^([a-z0-9]+)-(.+)$" integrity;
      derive = {
        ${dep.name} = stdenv.mkDerivation({
          name = "npm-pure-${name}-${version}";
          version = version;
          src = fetchurl {
            url = resolved;
            ${hash[0]} = hash[1];
          };
        });
      };
    in
      builtins.concatMap(builtins.concatLists([ [ derive ] recursePureEntry(dep) ]));

  pureModules = recursePureEntry(json);
in
  stdenv.mkDerivation({
    name = json.name;
    version = json.version;
    src = ./testpackage-0.0.1.tgz;
    buildInputs = pureModules;
    installPhase = ''
      echo $pkgs
      '';
  })
