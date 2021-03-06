{ lib, fetchurl }: src:
  let
    # internal
    and = a: b:
      if a then
        if b then true else false
      else false;

    recursiveIterateRecreate = set: iter:
      builtins.listToAttrs(
        builtins.concatMap iter (builtins.attrNames set)
      );

    # private util
    recursiveIterateReplace = deps: opts:
      recursiveIterateRecreate deps (name:
        if and (lib.hasAttrByPath [name "dev"] deps) opts.production then
          [] # skip dev
        else
          [(lib.nameValuePair name (recursiveReplaceResolved deps.${name} opts))]
      );

    recursiveReplaceResolved = pkg: opts:
      recursiveIterateRecreate pkg (name:
        if name == "resolved" then # else change the resolved url to a resolved hash
          if pkg ? link then # this is when we are referncing a file
            [(lib.nameValuePair name pkg.resolved)] # don't touch since the file is copied with source anyways
            # [(lib.nameValuePair name "${src + "/" + pkg.resolved}")]
          else
          let
            hash = builtins.match "^([a-z0-9]+)-(.+)$" pkg.integrity;
            fetched = fetchurl {
              url = pkg.resolved;
              ${builtins.elemAt hash 0} = builtins.elemAt hash 1;
            };
          in
            [(lib.nameValuePair name "file://${fetched}")]
        else if name == "version" && (lib.hasPrefix "file" pkg.version) then # else change to local file (version=file:path/to/folder)
          [(lib.nameValuePair name pkg.version)] # don't touch since the file is copied with source anyways
          # [(lib.nameValuePair name "file:${src + "/" + (builtins.substring 5 (builtins.stringLength pkg.version) pkg.version)}")]
        else if name == "version" && (lib.hasPrefix "http" pkg.version) then # else change the resolved url (that is the version) to a resolved hash
          let
            hash = builtins.match "^([a-z0-9]+)-(.+)$" pkg.integrity;
            fetched = fetchurl {
              url = pkg.version;
              ${builtins.elemAt hash 0} = builtins.elemAt hash 1;
            };
          in # this is when we install directly from a tarball as dependency
            [(lib.nameValuePair name "file://${fetched}") (lib.nameValuePair "resolved" "file://${fetched}")]
        else if name == "dependencies" && opts.version == 1 then
          [(lib.nameValuePair name (recursiveIterateReplace pkg.dependencies opts))]
        else
          [(lib.nameValuePair name pkg.${name})]
      );

    recreateLockfile = lock: opts:
      recursiveIterateRecreate lock (name:
        if name == "dependencies" && opts.version == 1 then
          [(lib.nameValuePair name (recursiveIterateReplace lock.dependencies opts))]
        else if name == "dependencies" && opts.version == 2 then
          [(lib.nameValuePair name (recursiveIterateReplace lock.dependencies (opts // { version = 1; })))]
        else if name == "packages" && opts.version == 2 then
          [(lib.nameValuePair name (recursiveIterateReplace lock.packages opts))]
        else
          [(lib.nameValuePair name lock.${name})]
    );

    # public util
    prepareLockfile = json: production:
      let
        newJson = recreateLockfile json { production = if json.lockfileVersion < 2 then production else false; version = json.lockfileVersion; };
      in
        builtins.toJSON newJson;
  in {
    prepareLockfile = prepareLockfile;
    concatAttrs = a: b: # just a level-1 concat for lists only, due to perf
      a // recursiveIterateRecreate b (key:
        if lib.hasAttrByPath [ key ] a && builtins.isList a.${key} && builtins.isList b.${key} then
          [(lib.nameValuePair key (a.${key} ++ b.${key}))]
        else
          [(lib.nameValuePair key b.${key})]
      );
  }
