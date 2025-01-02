{
  pkgs ? import <nixpkgs> { overlays = [ (import <rust-overlay>) ]; },
}:
let
  rust = pkgs.rust-bin.selectLatestNightlyWith (
    toolchain: toolchain.default.override { extensions = [ "rust-src" ]; }
  );
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    nixfmt-rfc-style

    openssl
    pkg-config
    rust
  ];

  RUST_BACKTRACE = 1;
  RUST_SRC_PATH = "${rust}/lib/rustlib/src/rust/library";
}
