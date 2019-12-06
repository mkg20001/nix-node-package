{ lib, fetchurl, stdenv, jq, ... }:
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
          nativeBuildInputs = [ jq ];

          installPhase = ''
            npm pack
            tar xfz "${tarball}"
            mv package "$out"

            cd "$out"
            echo '${lockfilePrepared}' > "package-lock.json"
            npm i ${if production then "--production" else ""}

            mkdir $out/bin
            # TODO: will possibly break if .bin is literal string (in which case we need to map it to {key: .name, value: .bin})
            cat "$out/package.json" | jq -r --arg out "$out" 'select(.bin != null) | .bin | to_entries | .[] | ["ln", "-s", $out + "/" + .value, $out + "/bin/" + .key] | join(" ")' | sh -ex -
            '';
        } // attrs);
  in
    makeNode
