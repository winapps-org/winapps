{
  stdenv,
  lib,
  fetchFromGitHub,
  makeWrapper,
  makeDesktopItem,
  yad,
  winapps ? throw "Pass in the winapps package",
  ...
}:
let
  rev = "87f92a80c7e421ab7d1b8801e647dcbfaaa6ee34";
  hash = "sha256-aZ8uusg5yQOD1xYfaX2IQCbcPdHuVA0tiy1NDkdGCCs=";
in
stdenv.mkDerivation rec {
  pname = "winapps-launcher";
  version = "0-unstable-2025-09-01";

  src = fetchFromGitHub {
    owner = "winapps-org";
    repo = "WinApps-Launcher";

    inherit rev hash;
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    yad
    winapps
  ];

  patches = [ ./WinApps-Launcher.patch ];

  postPatch = ''
    substituteAllInPlace WinApps-Launcher.sh
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r ./Icons $out/Icons

    install -m755 -D WinApps-Launcher.sh $out/bin/winapps-launcher
    install -Dm444 -T Icons/AppIcon.svg $out/share/pixmaps/winapps.svg

    wrapProgram $out/bin/winapps-launcher \
      --set LIBVIRT_DEFAULT_URI "qemu:///system" \
      --prefix PATH : "${lib.makeBinPath buildInputs}"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "winapps";
      exec = "winapps-launcher";
      icon = "winapps";
      comment = meta.description;
      desktopName = "WinApps";
      categories = [ "Utility" ];
    })
  ];

  meta = with lib; {
    homepage = "https://github.com/winapps-org/WinApps-Launcher";
    description = "Graphical launcher for WinApps. Run Windows applications (including Microsoft 365 and Adobe Creative Cloud) on GNU/Linux with KDE, GNOME or XFCE, integrated seamlessly as if they were native to the OS. Wayland is currently unsupported.";
    mainProgram = "winapps-launcher";
    platforms = platforms.linux;
    license = licenses.gpl3;
  };
}
