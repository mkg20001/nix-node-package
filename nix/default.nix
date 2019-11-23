{ lib, fetchurl, stdenv, ... }:
  with (import ./util.nix { lib = lib; fetchurl = fetchurl; });
  let
    makeNode = {root, nodejs, production ? true}: attrs:
      let
        # code
        json = builtins.fromJSON(builtins.readFile "${root}/package-lock.json"); # TODO: also support yarn.lock
        lockfilePrepared = prepareLockfile json production;
        safename = builtins.replaceStrings ["@" "/"] ["" "-"] json.name;
        tarball = "${safename}-${json.version}.tgz";
      in
        stdenv.mkDerivation({
          name = safename;
          version = json.version;

          src = root;

          buildInputs = [ nodejs ];

          installPhase = ''
            npm pack
            tar xfz "${tarball}"
            mv package "$out"

            cd "$out"
            echo '${lockfilePrepared}' > "package-lock.json"
            npm i ${if production then "--production" else ""}
            ls -lar $out
            '';
        } // attrs);
  in
    makeNode
