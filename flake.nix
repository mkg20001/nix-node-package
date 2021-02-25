{
  description = "nix-node-package";

  outputs = { self }: {

    lib.nix-node-package = import ./nix;

  };
}
