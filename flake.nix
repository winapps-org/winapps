{
  description = "WinApps Nix packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      nix-filter,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      rec {
        formatter = pkgs.nixfmt;

        packages = {
          winapps = pkgs.callPackage ./packages/winapps { inherit nix-filter; };
          winapps-launcher = pkgs.callPackage ./packages/winapps-launcher {
            inherit (packages) winapps;
          };
        };

        checks = {
          build-winapps = packages.winapps;
          build-launcher = packages.winapps-launcher;
        };
      }
    );
}
