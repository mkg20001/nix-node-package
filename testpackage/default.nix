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
            # TODO: add
          }

          installDep() {
            # TODO: add
          }

          installDeps() {
            local level="$1"

            mkdir node_modules
            pushd node_modules

            for dep in ${deps[$level]}; do
              getDepName $dep
              installDep $dep $depName

              pushd $depName
              installDeps "$level/$depName"
              popd
            done

            popd
          }
          '';
      });
in
  makeNode(./.)
