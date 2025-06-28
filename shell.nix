{
  pkgs ? import <nixpkgs> { },
  fenix ?
    import
      (fetchTarball "https://github.com/nix-community/fenix/archive/6643d56d9a78afa157b577862c220298c09b891d.tar.gz")
      {
        inherit pkgs;
      },
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
    ''
      sed -i \
        -e "s|$(${xidel} .idea/workspace.xml -e '${pathFor "explicitPathToStdlib"}')|${RUST_SRC_PATH}|" \
        -e "s|$(${xidel} .idea/workspace.xml -e '${pathFor "toolchainHomeDirectory"}')|${fenix.complete.toolchain}/bin|" \
        .idea/workspace.xml
    '';
}
