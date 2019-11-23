with (import <nixpkgs> {});
let
  makeNode = root: {nodejs}:
    let
      recursiveIterateRecreate = set: iter:
        builtins.listToAttrs(
          builtins.concatMap iter (builtins.attrNames set)
        );

      recursiveIterateReplace = deps:
        map (dep: recursiveReplaceResolved pkg) deps;

      recursiveReplaceResolved = pkg:
        builtins.listToAttrs(
          builtins.concatMap (name:
            if name == "resolved"
            then
              let
                hash = builtins.match "^([a-z0-9]+)-(.+)$" pkg.integrity;
                fetched = fetchurl {
                  url = pkg.resolved;
                  ${builtins.elemAt hash 0} = builtins.elemAt hash 1;
                };
              in
                [(nameValuePair name fetched)]
            else
              if name == "dependencies"
              then
                [(nameValuePair name (recursiveIterateReplace pkg.dependencies))]
              else
                pkg.${name}
          ) (builtins.attrNames pkg)
        );

      recreateLockfile = lock:



      _iterateFetchAllPackages = pkg: # TODO: make pure
        if pkg.dependencies != null then
          lib.mapAttrsToList (name: dep: # TODO: simplify
            dep
            # fetchAllPackages({ pkg = dep; name = name; })
          ) pkg.dependencies
        else
          pkg;

      fetchAllPackages = { pkg, name }: # TODO: make pure
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
          newJson = recursiveReplaceResolved json;
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

          echo "${lockfileNew}"
          cp "${lockfileNew}" "package-lock.json"
          npm i
          '';
      });
in
  makeNode(./.)({ nodejs = nodejs-10_x; })
