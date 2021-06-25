{ lib
, fetchurl
, stdenv
, jq
, nukeReferences
, writeText
, python3
, ...
}:
  with lib;
  let
    u = import ./util.nix { lib = lib; fetchurl = fetchurl; };

    makeNode = {
      root,
      packageLock ? null,
      yarnLock ? null,

      nodejs,
      production ? true,
      build ? false,
      buildProduction ? false
    }: attrs:
      with u root;
      let
        # code
        jsonFile = if (packageLock != null) then packageLock else "${root}/package-lock.json"; # TODO: yarn.lock
        json = builtins.fromJSON(builtins.readFile jsonFile); # TODO: also support yarn.lock
        lockfilePrepared = prepareLockfile json (production && buildProduction);
        safename = builtins.replaceStrings ["@" "/"] ["" "-"] json.name;
        tarball = "${safename}-${json.version}.tgz";
      in
        stdenv.mkDerivation(concatAttrs {
          pname = safename;
          version = json.version;

          src = root;

          lockfile = writeText "package-lock.json" lockfilePrepared;

          buildInputs = [ nodejs ];

          nativeBuildInputs = [ jq nukeReferences python3 ];

          prePhases = [ "nodeExports" ];

          nodeExports = ''
            # fix update check failed errors
            export NO_UPDATE_NOTIFIER=true
            # fix node weirdness
            export HOME=$(mktemp -d)
          '';

          preBuildPhases = [ "nodeGypHeaders" "nodeBuildPhase" ];

          nodeGypHeaders = ''
            NODE_VERSION=$(node --version | sed "s|v||g")
            GYP_FOLDER="$HOME/.cache/node-gyp/$NODE_VERSION"
            mkdir -p "$GYP_FOLDER"
            ln -s ${nodejs}/include "$GYP_FOLDER/include"
            echo 9 > "$GYP_FOLDER/installVersion"
          '';

          nodeBuildPhase = if build then ''
            cat $lockfile > "package-lock.json"
            npm ci --ignore-scripts ${if buildProduction then "--production" else ""}
            patchShebangs node_modules
            npm rebuild
          '' else "true";

          preInstallPhases = [ "nodeInstallPhase" ];

          nodeInstallPhase = ''
            npm pack
            tar xfz "${tarball}"
            mkdir -p "$out"
            cp -a package/. "$out"

            cd "$out"

            cat $lockfile > "package-lock.json"
            npm ci --ignore-scripts ${if production then "--production" else ""}
            patchShebangs node_modules
            npm rebuild

            mkdir -p $out/bin
            # TODO: will possibly break if .bin is literal string (in which case we need to map it to {key: .name, value: .bin})
            cat "$out/package.json" | jq -r --arg out "$out" 'select(.bin != null) | .bin | to_entries | .[] | ["ln", "-s", $out + "/" + .value, $out + "/bin/" + .key] | join(" ")' | sh -ex -

            nuke-refs "$out/package-lock.json"
            nuke-refs "$out/node_modules/.package-lock.json"
            for f in $(find -iname package.json); do
              nuke-refs "$f"
            done
          '';

          installPhase = "true"; # add dummy install phase so it won't fail, user can override this
        } attrs);
  in
    makeNode
