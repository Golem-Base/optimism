{
  description = "";
  inputs = {
    devshell = {
      url = "github:numtide/devshell";
      inputs.systems.follows = "systems";
    };
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    foundry.url = "github:shazow/foundry.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      foundry,
      ...
    }@inputs:
    let
      eachSystem =
        f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f (
            import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
              };
              overlays = [ foundry.overlay ];
            }
          )
        );
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = [ pkgs.foundry-bin ];
          packages = [
            pkgs.go
            pkgs.goda
            pkgs.gopls
            pkgs.gops
            pkgs.goreman
            pkgs.just
          ];
        };
      });
    };
}
