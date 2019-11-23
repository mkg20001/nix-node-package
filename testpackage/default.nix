with (import <nixpkgs> {});
let
  makeNode = root: {nodejs}:
    let
      _iterateFetchAllPackages = pkg:
        lib.mapAttrsToList (name: dep: # TODO: simplify
          fetchAllPackages({ pkg = dep; name = name; })
        ) pkg.dependencies;

      fetchAllPackages = { pkg, name }:
        let
          hash = builtins.match "^([a-z0-9]+)-(.+)$" pkg.integrity;
          fetched = fetchurl {
            url = pkg.resolved;
            ${builtins.elemAt hash 0} = builtins.elemAt hash 1;
          };
          pkg.resolved = "file://${fetched}";
          iterated = _iterateFetchAllPackages pkg;
        in
          pkg;

      prepareLockfile = json:
        let
          newJson = _iterateFetchAllPackages json;
        in
          builtins.toFile "package-lock.json" (builtins.toJSON newJson);

      json = builtins.fromJSON(builtins.readFile "${root}/package-lock.json"); # TODO: also support yarn.lock
      lockfileNew = prepareLockfile json;

    in
      stdenv.mkDerivation({
        name = json.name;
        version = json.version;

        src = root;

        buildInputs = [ nodejs ];

        installPhase = ''
          mv "$PWD" "$out"
          cd "$out"

          cp "${lockfileNew}" "package-lock.json"
          npm i
          '';
      });
in
  makeNode(./.)({ nodejs = nodejs-10_x; })
