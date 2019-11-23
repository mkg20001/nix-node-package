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
        recursiveIterateRecreate pkg (name:
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
        );

      recreateLockfile = lock:
        recursiveIterateRecreate lock (name:
          if name == "dependencies"
          then
            [(nameValuePair name (recursiveIterateReplace lock.dependencies))]
          else
            lock.${name}
      );

      prepareLockfile = json:
        let
          newJson = recreateLockfile json;
        in
          builtins.toFile "package-lock.json" (builtins.toJSON newJson);

      json = builtins.fromJSON(builtins.readFile "${root}/package-lock.json"); # TODO: also support yarn.lock
      lockfilePrepared = prepareLockfile json;

    in
      stdenv.mkDerivation({
        name = json.name;
        version = json.version;

        src = root;

        buildInputs = [ nodejs ];

        installPhase = ''
          mv "$PWD" "$out"
          cd "$out"

          echo "${lockfilePrepared}"
          cp "${lockfilePrepared}" "package-lock.json"
          npm i
          '';
      });
in
  makeNode(./.)({ nodejs = nodejs-10_x; })
