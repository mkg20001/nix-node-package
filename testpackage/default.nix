with (import <nixpkgs> {});
let
  makeNode = root:
    let
      json = builtins.fromJSON(builtins.readFile "${root}/package-lock.json"); # TODO: also support yarn.lock

      iterate = { tree, level, pkg, reqName ? "", isEntry ? false }:
        let
          tree.${level} = if pkg.dependencies != null
            then
              lib.mapAttrsToList (req: dep: # TODO: simplify
                iterate({ tree = tree; level = "${level}/${dep.name}"; reqName = req; pkg = dep; })
                ) pkg.dependencies
            else
              [];
          hash = builtins.match "^([a-z0-9]+)-(.+)$" pkg.integrity;
        in
          if isEntry then tree else stdenv.mkDerivation({ # return tree on entry, otherwise build tarball package
            name = "node-tarball-${builtins.replaceStrings ["@" "/"] ["=" "="] (pkg.name or reqName)}-${pkg.version}"; # FIXME: alphanum name
            version = pkg.version;

            src = fetchurl {
              url = pkg.resolved;
              ${builtins.elemAt hash 0} = builtins.elemAt hash 1;
            };

            installPhase = ''
              cp -vp * $out
              '';
          });

      bashArrayConvert = lib.mapAttrsToList(name: value: "[${name}]='${builtins.concatStringsSep " " value}'");

      setToString = set:
        builtins.concatStringsSep " " (bashArrayConvert(set));

      tree = iterate({ tree = rec {}; level = "/"; pkg = json; isEntry = true; });
    in
      stdenv.mkDerivation({
        name = json.name; # TODO: dynamic
        version = json.version; # TODO: dynamic

        src = root;

        # input: level = [ dep1 dep2 dep3 ]; level/level2 = [ dep4 dep2b ];

        installPhase = ''
          declare -A deps=(${setToString(tree)})

          # TODO: npm rebuild or emulation of npm rebuild?

          getDepName() {
            depName=$(cat "$1/package.json" | jq -r .name)
          }

          installDep() {
            ln -sv "$1/*" .
          }

          installDeps() {
            local level="$1"

            mkdir node_modules
            pushd node_modules

            for dep in {deps[$level]}; do
              getDepName $dep

              mkdir $depName
              pushd $depName

              installDep $dep
              installDeps "$level/$depName"

              popd
            done

            popd
          }

          installDeps "/"
          '';
      });
in
  makeNode(./.)
