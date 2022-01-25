{ lib, fetchurl }: src:
  let
    # internal
    parseIntegrity = builtins.match "^([a-z0-9]+)-(.+)$";
    parseYarn = builtins.match "^(.+)#([a-z0-9]+)$";

    findEntry = el: name: (lib.findSingle (el: el ? key && el.key._value == name) { value =  { _value = null; }; } { value =  { _value = null; }; } el.value).value._value;

    hasEntry = el: name: findEntry el name != null;

    recursiveIterateRecreate = set: iter:
      builtins.listToAttrs(
        builtins.concatMap iter (builtins.attrNames set)
      );

    # private util
    recursiveIterateReplace = deps: opts:
      recursiveIterateRecreate deps (name:
        if (lib.hasAttrByPath [name "dev"] deps) && opts.production then
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
            hash = parseIntegrity pkg.integrity;
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
            hash = parseIntegrity pkg.integrity;
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

    replaceInEntry = rep: entry:
      entry // {
        value = map (el: if el ? key && rep ? "${el.key._value}" then (if rep.${el.key._value} != null then {
          key = el.key;
          value = {
            _quoted = el.value._quoted;
            _value = rep.${el.key._value};
          };
        } else { empty = true; }) else el) entry.value;
      };

    processYarnEntry = entry: let
      f = findEntry entry;

      hash = parseIntegrity (f "integrity");

      y = parseYarn (f "resolved");

      fetched = fetchurl {
        url = builtins.elemAt y 0;
        ${builtins.elemAt hash 0} = builtins.elemAt hash 1;
      };
    in
      if entry ? empty then entry else
      if lib.hasPrefix "/" (f "resolved") then entry # if we have a local file path, just copy
      else replaceInEntry {
        resolved = "${fetched}${if builtins.elemAt y 1 != null then "#${builtins.elemAt y 1}" else ""}";
      } entry;

    # public util
    prepareLockfile = json: production:
      let
        newJson = recreateLockfile json { production = if json.lockfileVersion < 2 then production else false; version = json.lockfileVersion; };
      in
        builtins.toJSON newJson;

    # FIXME: stub
    prepareYarnLockfile = { yarnLockfile, nodejs, runCommand }: let
      exec = sc: file: runCommand "yarn.lock" {
        inherit file;
        passAsFile = if lib.hasPrefix "/" file then [] else [ "file" ];
      }
      ''
        if [ ! -z $filePath ]; then
          ${nodejs}/bin/node ${sc} $filePath > $out
        else
          ${nodejs}/bin/node ${sc} $file > $out
        fi
      '';

      json = builtins.fromJSON (builtins.readFile (exec ./yarn_parser.mjs yarnLockfile));

      out = map processYarnEntry json.root;
    in
      exec ./yarn_stringify.mjs (builtins.toJSON {
        comment = json.comment;
        root = out;
      });
  in {
    inherit prepareLockfile prepareYarnLockfile;

    concatAttrs = a: b: # just a level-1 concat for lists only, due to perf
      a // recursiveIterateRecreate b (key:
        if lib.hasAttrByPath [ key ] a && builtins.isList a.${key} && builtins.isList b.${key} then
          [(lib.nameValuePair key (a.${key} ++ b.${key}))]
        else
          [(lib.nameValuePair key b.${key})]
      );
  }
