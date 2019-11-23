# nix-node-package

Use the power of nix to turn node packages into nix deriviations, just with a few lines of code.

```nix
let
  pkgs = import <nixpkgs> {};
  nixNodePackage = builtins.fetchGit {
    url = "git@github.com:mkg20001/nix-node-package";
    rev = "7704b3c55aa15a7b348b2eea732b59ac31eebf35";
  };
  makeNode = import "${nixNodePackage}/nix/default.nix" pkgs {
    root = ./.;
    nodejs = pkgs.nodejs-10_x;
  };
in makeNode { }
```
