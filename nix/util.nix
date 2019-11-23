{ lib, fetchurl, fetchgit, fetchFromGitHub }:
  let
    # internal
    and = a: b:
      if a then
        if b then true else false
      else false;

    startsWith = start: str:
      (builtins.substring 0 (builtins.stringLength start) str) == start;

    substrPrefix = pref: str:
      builtins.substring (builtins.stringLength pref) (builtins.stringLength str) str;

    recursiveIterateRecreate = set: iter:
      builtins.listToAttrs(
        builtins.concatMap iter (builtins.attrNames set)
      );

    # fetchgit wrapper
    npmFetchgit = url:
      let
        s = builtins.match "^(.+)#([a-z0-9]+)$" url; # path#revision

        path = builtins.elemAt s 0;
        revision = builtins.elemAt s 1;

        url =
          if startsWith "git:" path then #
            "TODO"
          else if startsWith "github:" path then # github:user/repo
            "https://github.com/${lib.removePrefix "github:" path}"
          else if startsWith "git+" path then # git+ssh://git@github.com/mkg20001/mkgs-tool.git
            lib.removePrefix "git+" path
          else
            "ERROR";
      in
        fetchgit {
          url = url;
          rev = revision;
        };

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
        if and (name == "version") (startsWith "git" pkg.version) then # if we are at the version tag and it starts with git
        # fetchgit, replace the version with a "true" version and add a resolved & integrity
          let
            fetched = npmFetchgit pkg.version;
            fpkg = builtins.fromJSON(builtins.readFile "${fetched}/package.json");
            version = fpkg.version;
            # TODO: make tar.gz, add integrity and resolved
          in
            [(lib.nameValuePair name version)]
        else if name == "resolved" then # else change the resolved url to a resolved hash
          let
            hash = builtins.match "^([a-z0-9]+)-(.+)$" pkg.integrity;
            fetched = fetchurl {
              url = pkg.resolved;
              ${builtins.elemAt hash 0} = builtins.elemAt hash 1;
            };
          in
            [(lib.nameValuePair name "file://${fetched}")]
        else if name == "dependencies" then
          [(lib.nameValuePair name (recursiveIterateReplace pkg.dependencies opts))]
        else
          [(lib.nameValuePair name pkg.${name})]
      );

    recreateLockfile = lock: opts:
      recursiveIterateRecreate lock (name:
        if name == "dependencies" then
          [(lib.nameValuePair name (recursiveIterateReplace lock.dependencies opts))]
        else
          [(lib.nameValuePair name lock.${name})]
    );

    # public util
    prepareLockfile = json: production:
      let
        newJson = recreateLockfile json { production = production; };
      in
        builtins.toJSON newJson;
  in {
    prepareLockfile = prepareLockfile;
  }
