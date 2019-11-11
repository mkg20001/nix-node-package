let
  flatTree = deps: # TODO: filter out .dev == true
    let
      integrity = builtins.match "^([a-z0-9]+)-(.+)$";
    in
      map (dep: {
        #[dep.pname] = stdenv.mkDerivation {
        #  pname = "npm-${dep.name}"; # TODO: split in pure and non-pure, so we can efficently re-use. non-pure would have node_modules, pure would just be specific pkg & version, dirty has node_modules links (dirty shouldn't be a package, instead it would just build all the links)
        #  version = dep.version;
        #  # TODO: inherit instead of whatever tf it does rn
        #  buildScript =
        #    ```
        #    cp -rp package/ $out
        #    mkdir $out/node_modules
        #    ```
        #    map ({key, value}:
        #      ```
        #      ln -s ${value} $out/node_modules/${key} # link derivation here
        #      ```
        #    ) flatTree(dep.dependencies)
            # TODO: link bins/mans
        #}
      }) deps;
in
  { root, lock, pkgs }: attrs: # TODO: get lock from "root + /package.lock.json"
    with pkgs;
    let
      json = (builtins.fromJSON(builtins.readFile lock)); # TODO: relative stuff, etc?
      defaultAttrs = {
        name = json.name;
        version = json.version;
        sources = {
          "node_modules" = flatTree(json);
        };

        buildScript = ''
          npm i -g --prefix=$out
          '';
      };
    in
    stdenv.mkDerivation (defaultAttrs // attrs)
