{
  description = "WinApps package and dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      rust-overlay,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        devShells.default = import ./shell.nix { inherit pkgs; };

        packages.winapps = pkgs.callPackage ./. { };
      }
    );
}
