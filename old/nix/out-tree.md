# pure + dirty in main package

```
+ src
  | index.js
+ node_modules
  + pkg
    $ src -> /nix/store/xxx-npm-pure-pkg-ver/src
      + index.js
    + node_modules
      + subpkg
        $ src -> /nix/store/xxx-npm-pure-subpkg-ver/src
          + inedx.js
  + otherpkg
    $ src -> /nix/store/xxx-npm-pure-pkg-ver/src
      + index.js
```
