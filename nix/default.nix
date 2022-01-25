{ lib
, fetchurl
, stdenv
, jq
, nukeReferences
, writeText
, python3
, yarn
, runCommand
, nodePackages
, ...
}:
  with lib;
  let
    u = import ./util.nix { lib = lib; fetchurl = fetchurl; };

    _yarn = yarn;

    makeNode = {
      root,
      package ? null,
      packageLock ? null,
      yarnLock ? null,

      nodejs,
      production ? true,
      build ? false,
      install ? true,
      buildProduction ? false,
      yarn ? yarnLock != null,
      npm ? !yarn
    }: attrs:
      with u root;
      let
        # code
        jsonFile = if (packageLock != null) then packageLock else
          if yarnLock != null then (if package != null then package else "${root}/package.json")
          else "${root}/package-lock.json";
        json = builtins.fromJSON(builtins.readFile jsonFile);

        yarnLockfile = if yarnLock != null then yarnLock else "${root}/yarn.lock";

        yarnLockfilePrepared = if yarn then prepareYarnLockfile { inherit nodejs yarnLockfile runCommand; } else null;
        npmLockfilePrepared = if npm
          then prepareLockfile json (production && buildProduction)
          else null;

        safename = builtins.replaceStrings ["@" "/"] ["" "-"] json.name;
        tarball = "${safename}-${json.version}.tgz";
      in
        stdenv.mkDerivation(concatAttrs {
          pname = safename;
          version = json.version;

          src = root;

          lockfile = if yarn then yarnLockfilePrepared
            else if npm then writeText "package-lock.json" npmLockfilePrepared
            else throw "no lockfile format";

          buildInputs = if yarn then [ nodejs (_yarn.override({ inherit nodejs; })) ] else [ nodejs ];

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

          nodeBuildPhase = if build then (if yarn then ''
            cat $lockfile > "yarn.lock"
            yarn --offline --ignore-scripts ${if buildProduction then "--production" else ""}
            patchShebangs node_modules
            # yarn rebuild --offline
          '' else ''
            cat $lockfile > "package-lock.json"
            npm ci --ignore-scripts ${if buildProduction then "--production" else ""}
            patchShebangs node_modules
            npm rebuild
          '') else "true";

          preInstallPhases = [ "nodeInstallPhase" ];

          nodeInstallPhase = if install then ''
            npm pack
            tar xfz "${tarball}"
            mkdir -p "$out"
            cp -a package/. "$out"

            cd "$out"

            ${if yarn then ''
              cat $lockfile > "yarn.lock"
              yarn --offline --ignore-scripts ${if production then "--production" else ""}
              patchShebangs node_modules
              # yarn rebuild --offline
            '' else ''
              cat $lockfile > "package-lock.json"
              npm ci --ignore-scripts ${if production then "--production" else ""}
              patchShebangs node_modules
              npm rebuild
            ''}

            mkdir -p $out/bin
            # TODO: will possibly break if .bin is literal string (in which case we need to map it to {key: .name, value: .bin})
            cat "$out/package.json" | jq -r --arg out "$out" 'select(.bin != null) | .bin | to_entries | .[] | ["ln", "-s", $out + "/" + .value, $out + "/bin/" + .key] | join(" ")' | sh -ex -

            ${if yarn then ''
              for f in $(find -iname yarn.lock); do
                nuke-refs "$f"
              done
            '' else ''
              nuke-refs "$out/package-lock.json"
              nuke-refs "$out/node_modules/.package-lock.json"
            ''}
            for f in $(find -iname package.json); do
              nuke-refs "$f"
            done
          '' else "true";

          installPhase = "true"; # add dummy install phase so it won't fail, user can override this
        } attrs);
  in
    makeNode
