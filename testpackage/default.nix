stdenv.mkDerivation({
  inherit import ../nix/node-package.nix "."
  pname = "test-package";
  inherit hello;
})
