{
  pkgs ? import <nixpkgs> { },
  fenix ?
    import
      (fetchTarball "https://github.com/nix-community/fenix/archive/monthly.tar.gz")
      {
        inherit pkgs;
      },
  isIdea ? false,
}:
pkgs.mkShell rec {
  buildInputs = with pkgs; [
    nixfmt-rfc-style

    freerdp
    sshpass

    openssl
    pkg-config
    fenix.complete.toolchain
  ];

  RUST_BACKTRACE = 1;
  RUST_SRC_PATH = "${fenix.complete.rust-src}/lib/rustlib/src/rust/library";

  shellHook =
    let
      pathFor = name: ''//component[@name="RustProjectSettings"]/option[@name="${name}"]/@value'';
      xidel = pkgs.lib.getExe pkgs.xidel;
    in
    pkgs.lib.optionalString isIdea ''
      sed -i \
        -e "s|$(${xidel} .idea/workspace.xml -e '${pathFor "explicitPathToStdlib"}')|${RUST_SRC_PATH}|" \
        -e "s|$(${xidel} .idea/workspace.xml -e '${pathFor "toolchainHomeDirectory"}')|${fenix.complete.toolchain}/bin|" \
        .idea/workspace.xml
    '';
}
