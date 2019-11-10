# nix-node-package

Use the power of nix to turn node packages into nix deriviations, just with 3 lines of code.

```nix
import ./nix/node-package.nix "./node-tree-or-inherit-whatev" {
  inherit nodejs-11.x;
}
```

TODOs:
- Make it work
- Include module itself via nixpkgs/fetchgit/fetchurl?
- Better de-dup
- Possibly split "npm rebuild" deriviation and main-tree deriviation to do even more de-dup

# Why not `node2nix`?

- De-duplication: This library tries to de-duplicate as much as possible...
- Flexibility: ...while still keeping the flexibility of semver-range based version-resolution in nodeJS...
- Simplicity: ...and allowing you to re-package npm into node without more than 10 lines of additional code in your repo
