{
  stdenv,
  lib,
  makeWrapper,
  freerdp,
  dialog,
  libnotify,
  netcat,
  iproute2,
  nix-filter ? throw "Pass github:numtide/nix-filter as an argument!",
  ...
}:
stdenv.mkDerivation rec {
  pname = "winapps";
  version = "0-unstable-2025-07-02";

  src = nix-filter {
    root = ./../..;
    include = [
      "apps"
      "install"
      "bin"
      "icons"
      "LICENSE.md"
      "COPYRIGHT.md"
      "setup.sh"
    ];
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    freerdp
    libnotify
    dialog
    netcat
    iproute2
  ];

  patches = [
    ./setup.patch
  ];

  postPatch = ''
    substituteAllInPlace bin/winapps
    substituteAllInPlace setup.sh
    patchShebangs install/inquirer.sh
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    mkdir -p $out/src

    cp -r ./ $out/src/

    install -m755 -D bin/winapps $out/bin/winapps
    install -m755 -D setup.sh $out/bin/winapps-setup

    for f in winapps-setup winapps; do
      wrapProgram $out/bin/$f \
        --set LIBVIRT_DEFAULT_URI "qemu:///system" \
        --prefix PATH : "${lib.makeBinPath buildInputs}"
    done

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/winapps-org/winapps";
    description = "Run Windows applications (including Microsoft 365 and Adobe Creative Cloud) on GNU/Linux with KDE, GNOME or XFCE, integrated seamlessly as if they were native to the OS. Wayland is currently unsupported.";
    mainProgram = "winapps";
    platforms = platforms.linux;
    license = licenses.agpl3Plus;
  };
}
