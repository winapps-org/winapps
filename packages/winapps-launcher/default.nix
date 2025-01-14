{
  stdenv,
  lib,
  fetchFromGitHub,
  makeWrapper,
  makeDesktopItem,
  callPackage,
  yad,
  ...
}:
let
  rev = "3eb63ad1442068119c2e0f2586e6d63e7a45042e";
  hash = "sha256-y31AdBZSiarcQzH2wyDnhzgrrELbLW4XY94JvLejoTU=";
in
stdenv.mkDerivation rec {
  pname = "winapps-launcher";
  version = "0-unstable-2025-01-12";

  src = fetchFromGitHub {
    owner = "winapps-org";
    repo = "WinApps-Launcher";

    inherit rev hash;
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    yad
    (callPackage ../winapps { })
  ];

  patches = [ ./WinAppsLauncher.patch ];

  postPatch = ''
    substituteAllInPlace WinAppsLauncher.sh
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r ./Icons $out/Icons

    install -m755 -D WinAppsLauncher.sh $out/bin/winapps-launcher
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
