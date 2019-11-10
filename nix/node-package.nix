let
  flatTree = deps: # TODO: filter out .dev == true
    map deps dep: {
      stdenv.mkDerivation {
        pname = "npm-${dep.name}";
        version = dep.version;
        sources = flatTree(dep.dependencies);
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
