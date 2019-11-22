# conversion tree 1

```nix
{
  "some-package": {
    "1.2.3": {
      name = "some-package";
      version = "1.2.3";
      src = fetchurl {
        url = "...";
        ${hash[0]} = hash[1];
      }

      installPhase = ''
        cp -vp * $out
        ''
    }
  }
}
```

it'll go through this and use stdenv.mkDerivation to get a path

# conversion tree 1.1

```nix
{
  "some-package": {
    "1.2.3": "/nix/store/..."
  }
}
```

it'll go through this to create a output tree as defined in out-tree.md

# conversion tree 2

TODO: do we really need this?

we could override stuff to add build-assets (node-gyp stuff)

or we could simply ignore this step and then just use another method

```nix
{
  name = "main-package";
  version = "1.0.0";
  src = ...;

  dependencies = {
    "sub-package" = {
      name = "sub-package";
      version = "1.0.0";
      src = ...;

      dependencies = { ... };
    }
  };
}
```
