#!/usr/bin/env python3

import platform
import os
import shutil
import sys


def _(c: str):
    """Execute the command `c` and print it"""
    print("> " + c)
    os.system(c)


def clone_repo():
    if os.path.exists(os.path.expanduser("~/.local/share/quickemu")):
        print("📦 quickemu is already installed. Updating...")
        update_quickemu()
        return

    print("📦 Cloning quickemu...")

    _("git clone --filter=blob:none https://github.com/quickemu-project/quickemu ~/.local/share/quickemu")
    _("mkdir -p ~/.local/bin")
    _("ln -s ~/.local/share/quickemu/quickemu ~/.local/bin/quickemu")
    _("ln -s ~/.local/share/quickemu/macrecovery ~/.local/bin/macrecovery")
    _("ln -s ~/.local/share/quickemu/quickget ~/.local/bin/quickget")
    _("ln -s ~/.local/share/quickemu/windowskey ~/.local/bin/windowskey")

    print("Installation complete.")
    print("⚠️ Make sure ~/.local/bin is in your PATH.")


def update_quickemu():
    print("📦 Updating quickemu...")

    _("cd ~/.local/share/quickemu")
    _("git pull")

    print("Update complete.")
    print("⚠️ Make sure ~/.local/bin is in your PATH.")


def install_fedora():
    print("📦 Installing dependencies...")

    _("sudo dnf install qemu bash coreutils edk2-tools grep jq lsb procps python3 genisoimage usbutils"
        + " util-linux sed spice-gtk-tools swtpm wget xdg-user-dirs xrandr unzip socat -y")

    clone_repo()

    sys.exit(0)


def install_deb():
    print("📦 Installing dependencies...")

    _("sudo apt update")
    _("sudo apt install qemu bash coreutils ovmf grep jq lsb-base procps python3 genisoimage usbutils"
        + " util-linux sed spice-client-gtk libtss2-tcti-swtpm0 wget xdg-user-dirs zsync unzip socat -y")

    clone_repo()

    sys.exit(0)


def install_ubuntu():
    print("⚠️ Adding ppa...")

    _("sudo apt-add-repository ppa:flexiondotorg/quickemu")
    _("sudo apt update")
    _("sudo apt install quickemu -y")

    sys.exit(0)


if __name__ == "__main__":
    print("⚠️ This script requires elevated privileges (sudo). You will be asked for your password.")

    os_release = platform.freedesktop_os_release()

    distro_id = os_release.get("ID_LIKE")
    distro_id_like = os_release.get("ID")

    if not distro_id and not distro_id_like:
        print("❌ Couldn't fetch distro, is os-release installed?")

    if distro_id == "ubuntu" \
            or distro_id_like == "ubuntu":
        install_ubuntu()
    elif distro_id == "debian" \
            or distro_id_like == "debian" \
            or shutil.which("apt"):
        install_deb()
    elif distro_id == "fedora" \
            or distro_id_like == "fedora" \
            or shutil.which("dnf"):
        install_fedora()
    else:
        if distro_id:
            print("❌ Unsupported distro: ", distro_id)
        elif distro_id_like:
            print("❌ Unsupported distro: ", distro_id_like)
        else:
            print("❌ Unsupported distro. Couldn't fetch data from os-release and couldn't find dnf or apt on PATH.")

        sys.exit(1)

    print("❌ Unsupported platform.")
    sys.exit(1)
