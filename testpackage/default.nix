with (import <nixpkgs> {});
let
  makeNode = root:
    let
      json = builtins.fromJSON(builtins.readFile "${root}/package-lock.json"); # TODO: also support yarn.lock

      iterate = { tree, level, pkg }:
        let
          tree.${level} = map (dep:
            iterate({ tree = tree; level = "${level}/${dep.name}"; pkg = dep; })
          ) pkg.dependencies;
          hash = builtins.match "^([a-z0-9]+)-(.+)$" pkg.integrity;
        in
          stdenv.mkDerivation({
            name = "node-tarball-${pkg.name}-${pkg.version}";
            version = pkg.version;

            src = fetchurl {
              url = pkg.resolved;
              ${hash[0]} = hash[1];
            };

            installPhase = ''
              cp -vp * $out
              '';
          });
    in
      stdenv.mkDerivation({
        name = json.name; # TODO: dynamic
        version = json.version; # TODO: dynamic

        src = root;

        # input: level = [ dep1 dep2 dep3 ]; level/level2 = [ dep4 dep2b ];

        installPhase = ''
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
          '';
      });
in
  makeNode(./.)
