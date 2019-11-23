{ lib, fetchurl, stdenv, ... }:
  with (import ./util.nix { lib = lib; fetchurl = fetchurl; });
  let
    makeNode = {root, nodejs, production ? true}: attrs:
      let
        # code
        json = builtins.fromJSON(builtins.readFile "${root}/package-lock.json"); # TODO: also support yarn.lock
        lockfilePrepared = prepareLockfile json production;
      in
        stdenv.mkDerivation({
          name = builtins.replaceStrings ["@" "/"] ["" "-"] json.name;
          version = json.version;

          src = root;

          buildInputs = [ nodejs ];

          installPhase = ''
            mv "$PWD" "$out"
            cd "$out"

            echo '${lockfilePrepared}' > "package-lock.json"
            npm i ${if production then "--production" else ""}
            '';
        } // attrs);
  in
    makeNode
