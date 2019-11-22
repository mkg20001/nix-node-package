let
  d = {};
in
  { root, lock, pkgs }: attrs: # TODO: get lock from "root + /package.lock.json"
    with pkgs;
    let
      json = builtins.fromJSON(builtins.readFile lock); # TODO: relative stuff, etc?
    in
      stdenv.mkDerivation ({
        name = json.name;
        version = json.version;
        sources = {
          "node_modules" = flatTree(json);
        };

        buildScript = ''
          npm i -g --prefix=$out
          '';
      })
