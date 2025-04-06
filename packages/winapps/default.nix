{
  stdenv,
  lib,
  fetchFromGitHub,
  makeWrapper,
  freerdp3,
  dialog,
  libnotify,
  netcat,
  iproute2,
  ...
}:
let
  rev = "f6d56fdf50f3b801d03f8dca2cca2246485cb793";
  hash = "sha256-Yr6L33A9l6DW4IGBXKpPCUcA69XATxrYanwOBupSdPs=";
in
stdenv.mkDerivation rec {
  pname = "winapps";
  version = "0-unstable-2025-04-05";

  src = fetchFromGitHub {
    owner = "winapps-org";
    repo = "winapps";

    inherit rev hash;
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    freerdp3
    libnotify
    dialog
    netcat
    iproute2
  ];

  patches = [
    ./winapps.patch
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
