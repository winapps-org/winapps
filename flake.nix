{
  description = "WinApps package and dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crane.url = "github:ipetkov/crane";

    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    crane,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        inherit (pkgs) lib;

        pkgs = import nixpkgs {
          inherit system;
          overlays = [(import rust-overlay)];
        };

        craneLib = (crane.mkLib pkgs).overrideToolchain (p: p.rust-bin.selectLatestNightlyWith (toolchain: toolchain.minimal));
        src = craneLib.cleanCargoSource ./.;

        buildWorkspacePackage = {pname, ...} @ extraAttrs:
          craneLib.buildPackage (
            extraAttrs
            // {
              inherit src;
              inherit (craneLib.crateNameFromCargoToml {cargoToml = ./${pname}/Cargo.toml;}) version;
              cargoExtraArgs = "-p ${pname}";
            }
          );
      in {
        formatter = pkgs.nixfmt-rfc-style;
        devShells.default = import ./shell.nix {inherit pkgs;};

        packages.winapps = buildWorkspacePackage {
          pname = "winapps-cli";

          nativeBuildInputs = [pkgs.makeWrapper];

          postInstall = ''
            wrapProgram $out/bin/winapps-cli \
             --prefix PATH : ${lib.makeBinPath [pkgs.freerdp3]}

            ln -s $out/bin/winapps-cli $out/bin/winapps
          '';
        };
      }
    );
}
