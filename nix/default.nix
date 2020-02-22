{ lib
, fetchurl
, stdenv
, jq
, nukeReferences
, ...
}:
  with lib;
  with (import ./util.nix { lib = lib; fetchurl = fetchurl; });
  let
    makeNode = {root, nodejs, production ? true, build ? true, buildProduction ? false}: attrs:
      let
        # code
        json = builtins.fromJSON(builtins.readFile "${root}/package-lock.json"); # TODO: also support yarn.lock
        lockfilePrepared = prepareLockfile json (production && buildProduction);
        safename = builtins.replaceStrings ["@" "/"] ["" "-"] json.name;
        tarball = "${safename}-${json.version}.tgz";
      in
        stdenv.mkDerivation(concatAttrs {
          pname = safename;
          version = json.version;

          src = root;

          buildInputs = [ nodejs ];

          nativeBuildInputs = [ jq nukeReferences ];

          prePhases = [ "nodeExports" ];

          nodeExports = ''
            # fix update check failed errors
            export NO_UPDATE_NOTIFIER=true
          '';

          preBuildPhases = [ "nodeBuildPhase" ];

          nodeBuildPhase = if build then ''
            echo ${escapeShellArg lockfilePrepared} > "package-lock.json"
            HOME=/tmp npm i ${if buildProduction then "--production" else ""}
          '' else "true";

          preInstallPhases = [ "nodeInstallPhase" ];

          nodeInstallPhase = ''
            npm pack
            tar xfz "${tarball}"
            mv package "$out"

            cd "$out"
            echo '${lockfilePrepared}' > "package-lock.json"
            HOME=/tmp npm i ${if production then "--production" else ""}

            mkdir -p $out/bin
            # TODO: will possibly break if .bin is literal string (in which case we need to map it to {key: .name, value: .bin})
            cat "$out/package.json" | jq -r --arg out "$out" 'select(.bin != null) | .bin | to_entries | .[] | ["ln", "-s", $out + "/" + .value, $out + "/bin/" + .key] | join(" ")' | sh -ex -

            nuke-refs "$out/package-lock.json"
          '';

          installPhase = "true"; # add dummy install phase so it won't fail, user can override this
        } attrs);
  in
    makeNode
