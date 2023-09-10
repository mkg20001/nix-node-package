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
      test ? false,
      install ? true,
      buildProduction ? false,
      yarn ? yarnLock != null,
      npm ? !yarn
    }: attrs:
      with u root;
      let
        # newer nodePackages are broken so we have to use hacks
        # nodePackages = nodejs.pkgs;

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

        genInstall = isProd: ''
          ${if yarn then ''
            cat $lockfile > "yarn.lock"
            yarn --frozen-lockfile --offline --ignore-scripts ${if isProd then "--production" else ""}
          '' else ''
            cat $lockfile > "package-lock.json"
            npm ci --ignore-scripts ${if isProd then "--production" else ""}
          ''}
          # the gyp hack
          GYP=$(mktemp -d)
          cp -rp ${nodePackages.node-gyp}/lib/node_modules/node-gyp "$GYP/mod"
          chmod +w -R "$GYP/mod"
          find "$GYP/mod" -type f -exec sed -i \
            -e "s|/nix/store/[a-z0-9]*-nodejs-[0-9.]*|${nodejs}|g" \
            {} +

          # patch to automatically use latest node-gyp
          for g in $(find -iwholename "*/node_modules/node-gyp" -type d); do
            rm -rf "$g"
            ln -sf "$GYP/mod" "$g"
          done
          patchShebangs node_modules
          npm rebuild
        '';
      in
        stdenv.mkDerivation(concatAttrs {
          pname = safename;
          version = json.version;

          src = root;

          lockfile = if yarn then yarnLockfilePrepared
            else if npm then writeText "package-lock.json" npmLockfilePrepared
            else throw "no lockfile format";

          buildInputs = if yarn then [ nodejs (_yarn.override({ inherit nodejs; })) ] else [ nodejs ];

          nativeBuildInputs = [ jq nukeReferences python3 nodePackages.node-gyp ];

          prePhases = [ "nodeExports" "nodeGypHeaders" ];

          nodeExports = ''
            # fix update check failed errors
            export NO_UPDATE_NOTIFIER=true
            # fix node weirdness
            export HOME=$(mktemp -d)
          '';

          nodeGypHeaders = ''
            NODE_VERSION=$(node --version | sed "s|v||g")
            GYP_FOLDER="$HOME/.cache/node-gyp/$NODE_VERSION"
            mkdir -p "$GYP_FOLDER"
            cp -rp ${nodejs}/include "$GYP_FOLDER/include"
            chmod aog+w -R "$GYP_FOLDER/include"
            echo 9 > "$GYP_FOLDER/installVersion"
          '';

          preBuildPhases = [ "nodeBuildPhase" ];

          nodeBuildPhase = if build then (genInstall buildProduction) else "true";

          preInstallPhases = [ "nodeInstallPhase" ];

          checkPhase = if !test then null else if !build then builtins.throw "[nix-node-package] test option needs build option enabled" else ''
            npm run test
          '';

          nodeInstallPhase = if install then ''
            npm pack
            tar xfz "${tarball}"
            mkdir -p "$out"
            cp -a package/. "$out"

            cd "$out"

            ${genInstall production}
            # clean up the reference
            find -iwholename "*/node_modules/node-gyp" -type d -delete

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

          # add dummy install phase so it won't fail, user can override this
          installPhase = ''
            runHook preInstall
            runHook postInstall
          '';
        } attrs);
  in
    makeNode
