# node-package

Takes a `root`

Reads `package-lock.json`

Recursivly creates a dependency tree
  - deps
  - treeStore

  for every dep in deps
    #if deps
    #  flatTree(deps, treeStore)
    treeStore["${dep.name}#${dep.version}"] =
    let integrity = /([a-z0-9]+)-(.+)/
    in {
      pname = dep.name;
      version = dep.version;

      for dep in dep.dependencies
        map flatTree(deps) :pkg
          inherit pkg

      src = fetchurl {
        url = dep.resolved;
        [integrity[1]] = integrity[2]; # $hashtype = hash # TODO: possibly need to map node-hash to nix-hash?
      }

      #for {key, value} in requires
      #  inherit "${key}#${value}"
    }
