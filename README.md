# nix-node-package

Use the power of nix to turn node packages into nix deriviations, just with a few lines of code.

```nix
let
  pkgs = import <nixpkgs> {};
  nixNodePackage = builtins.fetchGit {
    url = "git@github.com:mkg20001/nix-node-package";
    rev = "e9a2642b93d219a23d28df1081459341b620baf0";
  };
  makeNode = import "${nixNodePackage}/nix/default.nix" pkgs {
    root = ./.;
    nodejs = pkgs.nodejs-10_x;
  };
in makeNode { }
```
