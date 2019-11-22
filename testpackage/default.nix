with (import <nixpkgs> {});
let
  makeNode = root:
    let
      json = builtins.fromJSON(builtins.readFile "${root}/package-lock.json");
    in
      stdenv.mkDerivation({
        name = json.name; # TODO: dynamic
        version = json.version; # TODO: dynamic

        src = ./.;

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
