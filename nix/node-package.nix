let
  flatTree = deps: # TODO: filter out .dev == true
    map deps dep: {
      [dep.pname] = stdenv.mkDerivation {
        pname = "npm-${dep.name}"; # TODO: split in pure and non-pure, so we can efficently re-use. non-pure would have node_modules, pure would just be specific pkg & version
        version = dep.version;
        # TODO: inherit instead of whatever tf it does rn
        buildScript =
          ```
          cp -rp package/ $out
          mkdir $out/node_modules
          ```
          map ({key, value}:
            ```
            ln -s ${value} $out/node_modules/${value} # link derivation here
            ```
          ) flatTree(dep.dependencies)
          # TODO: link bins/mans
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
