{
  stdenv,
  lib,
  fetchFromGitHub,
  makeWrapper,
  freerdp3,
  dialog,
  libnotify,
  netcat-gnu,
  iproute2,
  ...
}: let
  rev = "350f003d817765ed9e6f4791e86c3d69019f230a";
  hash = "sha256-MqQ9KFyo6bZDxfWCe62z1zDSvHJJjvWqZLO4UxwELow=";
in
  stdenv.mkDerivation rec {
    pname = "winapps";
    version = "git+${rev}";

    src = fetchFromGitHub {
      owner = "winapps-org";
      repo = "winapps";

      inherit rev hash;
    };

    nativeBuildInputs = [makeWrapper];
    buildInputs = [freerdp3 libnotify dialog netcat-gnu iproute2];

    installPhase = ''
      runHook preInstall

      patchShebangs install/inquirer.sh

      mkdir -p $out
      mkdir -p $out/src

      cp -r ./ $out/src/

      install -m755 -D bin/winapps $out/bin/winapps
      install -m755 -D setup.sh $out/bin/winapps-setup

      sed -E -i \
        -e 's/grep -q -E "\\blibvirt\\b"/grep -q -E "\\blibvirtd\\b"/' \
        $out/bin/winapps

      sed -E -i \
        -e 's/grep -q -E "\\blibvirt\\b"/grep -q -E "\\blibvirtd\\b"/' \
        -e "$(printf "%s$out%s" 's|^readonly INQUIRER_PATH="./install/inquirer.sh"|readonly INQUIRER_PATH="' '/src/install/inquirer.sh"|')" \
        -e "$(printf "%s$out%s" 's|^readonly SYS_SOURCE_PATH="(.*?)"|readonly SYS_SOURCE_PATH="' '/src"|')" \
        -e "$(printf "%s$out%s" 's|^readonly USER_SOURCE_PATH="(.*?)"|readonly USER_SOURCE_PATH="' '/src"|')" \
        -e 's/\$SUDO git -C "\$SOURCE_PATH" pull --no-rebase//g' \
        -e 's|./setup.sh|winapps-setup|g' \
        -e 's|\$SUDO ln -s "./bin/winapps" "\$\{BIN_PATH\}/winapps"||' \
        -e 's|\$SUDO ln -s "./setup.sh" "\$\{BIN_PATH\}/winapps-setup"||' \
        -e "s|\$\{BIN_PATH\}/winapps|$out/bin/winapps|" \
        $out/bin/winapps-setup

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
      license = licenses.gpl3;
    };
  }
