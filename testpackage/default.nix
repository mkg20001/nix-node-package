with (import <nixpkgs> {});
let
  makeNode = root: {nodejs}:
    let
      # internal
      recursiveIterateRecreate = set: iter:
        builtins.listToAttrs(
          builtins.concatMap iter (builtins.attrNames set)
        );

      # private util
      recursiveIterateReplace = deps:
        recursiveIterateRecreate deps (name:
          if lib.hasAttrByPath [name "dev"] deps
          then
            [] # skip dev
          else
            [(lib.nameValuePair name (recursiveReplaceResolved deps.${name}))]
        );

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
              [(lib.nameValuePair name "file://${fetched}")]
          else
            if name == "dependencies"
            then
              [(lib.nameValuePair name (recursiveIterateReplace pkg.dependencies))]
            else
              [(lib.nameValuePair name pkg.${name})]
        );

      recreateLockfile = lock:
        recursiveIterateRecreate lock (name:
          if name == "dependencies"
          then
            [(lib.nameValuePair name (recursiveIterateReplace lock.dependencies))]
          else
            [(lib.nameValuePair name lock.${name})]
      );

      # public util

      prepareLockfile = json:
        let
          newJson = recreateLockfile json;
        in
          builtins.toJSON newJson;

      # code
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

          echo '${lockfilePrepared}' > "package-lock.json"
          npm i --production
          '';
      });
in
  makeNode(./.)({ nodejs = nodejs-10_x; })
