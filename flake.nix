{
  description = "nix-node-package";

  outputs = { self, nixpkgs }: {

    lib.nix-node-package = import ./nix nixpkgs;

  };
}
