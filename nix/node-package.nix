let
  flatTree = deps: # TODO: filter out .dev == true
    map deps dep: {
      stdenv.mkDerivation {
        pname = "npm-${dep.name}";
        version = dep.version;

      }
    }
in
  { root, attrs ? {} }:
    let json = importJSON(coerce(root, "package-lock.json"))
    in
    rec {
      pname = json.name;
      version = json.version;
      inherit flatTree(json.dependencies)
    } // attrs
