# nix-node-package

Use the power of nix to turn node packages into nix deriviations, just with 3 lines of code.

```nix
import ./nix/node-package.nix "./node-tree-or-inherit-whatev" {
  inherit nodejs-11.x;
}
```

TODOs:
- Make it work
- Include via nixpkgs/fetchgit/fetchurl?
- Better de-dup
- Possibly split "npm rebuild" deriviation and main-tree deriviation to do even more de-dup
