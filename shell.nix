{
  pkgs ?
    import <nixpkgs-unstable> {
      overlays = [(import <rust-overlay>)];
    },
}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    openssl
    pkg-config
    (rust-bin.selectLatestNightlyWith (toolchain:
      toolchain.default.override {
        extensions = ["rust-src"];
      }))
  ];
}
