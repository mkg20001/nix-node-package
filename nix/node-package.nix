let
  flatTree = deps: # TODO: filter out .dev == true
    map deps dep: {
      [dep.pname] = stdenv.mkDerivation {
        pname = "npm-${dep.name}";
        version = dep.version;
        buildScript =
          ```
          cp -rp package/ $out
          mkdir $out/node_modules
          ```
          map flatTree(dep.dependencies) {key, value}:
            ```
            ln -s ${value} $out/node_modules/${value}
            ```
      }
    }
in
  { root, attrs ? {} }:
    let json = importJSON(coerce(root, "package-lock.json"))
    in
    rec {
      pname = json.name;
      version = json.version;
      sources = {
        "node_modules" = flatTree(json)
      }

      buildScript = ''
        npm i -g --prefix=$out
        ''
    } // attrs
