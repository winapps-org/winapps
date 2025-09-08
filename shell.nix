{
  nixpkgs ? fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz",
  pkgs ? import nixpkgs { },
  fenix ?
    (import (fetchTarball "https://github.com/nix-community/fenix/archive/monthly.tar.gz") {
      inherit pkgs;
    }).complete,
  isIdea ? false,
}:
pkgs.mkShell rec {
  buildInputs = with pkgs; [
    nixfmt-rfc-style
    pre-commit

    freerdp
    sshpass

    openssl
    pkg-config
    fenix.toolchain
  ];

  RUST_BACKTRACE = 1;
  RUST_SRC_PATH = "${fenix.rust-src}/lib/rustlib/src/rust/library";

  shellHook =
    let
      pathFor = name: ''//component[@name="RustProjectSettings"]/option[@name="${name}"]/@value'';
      xidel = pkgs.lib.getExe pkgs.xidel;
    in
    pkgs.lib.optionalString isIdea ''
      sed -i \
        -e "s|$(${xidel} .idea/workspace.xml -e '${pathFor "explicitPathToStdlib"}')|${RUST_SRC_PATH}|" \
        -e "s|$(${xidel} .idea/workspace.xml -e '${pathFor "toolchainHomeDirectory"}')|${fenix.toolchain}/bin|" \
        .idea/workspace.xml
    '';
}
