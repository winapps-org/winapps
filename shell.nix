{
  nixpkgs ? fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz",
  fenix-src ? fetchTarball "https://github.com/nix-community/fenix/archive/monthly.tar.gz",

  mkToolchain ? fenix: fenix.complete,
  isIdea ? false,
}:
let
  pkgs = import nixpkgs { };
  fenix = import fenix-src { inherit pkgs; };
  toolchain = mkToolchain fenix;
in
pkgs.mkShell rec {
  buildInputs = with pkgs; [
    nixfmt-rfc-style
    pre-commit

    freerdp
    sshpass

    openssl
    pkg-config
    toolchain.toolchain
  ];

  RUST_BACKTRACE = 1;
  RUST_SRC_PATH = "${toolchain.rust-src}/lib/rustlib/src/rust/library";

  shellHook =
    let
      pathFor = name: ''//component[@name="RustProjectSettings"]/option[@name="${name}"]/@value'';
      xidel = pkgs.lib.getExe pkgs.xidel;
    in
    pkgs.lib.optionalString isIdea ''
      if [ -f .idea/workspace.xml ]; then
        sed -i \
          -e "s|$(${xidel} .idea/workspace.xml -e '${pathFor "explicitPathToStdlib"}')|${RUST_SRC_PATH}|" \
          -e "s|$(${xidel} .idea/workspace.xml -e '${pathFor "toolchainHomeDirectory"}')|${toolchain.toolchain}/bin|" \
          .idea/workspace.xml
      fi
    '';
}
