{
  description = "Polygon Bor Node";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    systems.url = "github:nix-systems/default";
    flake-compat.url = "github:nix-community/flake-compat";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      ...
    }:
    let
      # A helper that helps us define the attributes below for
      # all systems we care about.
      eachSystem =
        f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {
      packages = eachSystem (
        { pkgs, ... }:
        {
          default = pkgs.callPackage ./pkgs/bor/default.nix {
            lib = pkgs.lib;
            stdenv = pkgs.stdenv;
            buildGoModule = pkgs.buildGoModule;
            fetchFromGitHub = pkgs.fetchFromGitHub;
            libobjc = pkgs.darwin.libobjc;
            IOKit = pkgs.darwin.IOKit;
          };
        }
      );

      # NixOS module output for Bor
      nixosModules.default = import ./modules/bor/default.nix;
    };
}