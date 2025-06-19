# Winapps-Docker-Installation
<details open>
<summary>Step 1: Install Dependencies</summary>

Install the required dependencies.
- Debian/Ubuntu:
    ```bash
    sudo apt install -y curl dialog freerdp3-x11 git iproute2 libnotify-bin netcat-openbsd
    ```

> [!NOTE]
> On Debian you need to enable the `backports` repository for the `freerdp3-x11` package to become available.
> For instructions, see https://backports.debian.org/Instructions.

- Fedora/RHEL:
    ```bash
    sudo dnf install -y curl dialog freerdp git iproute libnotify nmap-ncat
    ```
- Arch Linux:
    ```bash
    sudo pacman -Syu --needed -y curl dialog freerdp git iproute2 libnotify gnu-netcat
    ```
- OpenSUSE:
    ```bash
    sudo zypper install -y curl dialog freerdp git iproute2 libnotify-tools netcat-openbsd
    ```
- Gentoo Linux:
    ```bash
    sudo emerge --ask=n net-misc/curl dev-util/dialog net-misc/freerdp:3 dev-vcs/git sys-apps/iproute2 x11-libs/libnotify net-analyzer/openbsd-netcat
    ```

> [!NOTE]
> WinApps requires `FreeRDP` version 3 or later. If not available for your distribution through your package manager, you can install the [Flatpak](https://flathub.org/apps/com.freerdp.FreeRDP):
> ```bash
> flatpak install flathub com.freerdp.FreeRDP
> sudo flatpak override --filesystem=home com.freerdp.FreeRDP # To use `+home-drive`
> ```
> However, if you have weird issues like [#233](https://github.com/winapps-org/winapps/issues/233) when running Flatpak, please compile FreeRDP from source according to [this guide](https://github.com/FreeRDP/FreeRDP/wiki/Compilation).

</details>

<details>
<summary>Windows Configuration Steps</summary>

Download [VirtIO drivers](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso)
Once in Windows open File Explorer and got to Network and find your Linux Home directory.
Press right click and seelct mount .iso file.
Just after navigate to the drive where the `VirtIO` driver `.ISO` is mounted. Run `virtio-win-gt-x64.exe` to launch the `VirtIO` driver installer.

<p align="center">
    <img src="./libvirt_images/24.png" width="700px"/>
</p>

Leave everything as default and click `Next` through the installer. This will install all required device drivers as well as the 'Memory Ballooning' service.

<p align="center">
    <img src="./libvirt_images/25.png" width="700px"/>
</p>

Next, install the `QEMU Guest Agent` within Windows. This agent allows the GNU/Linux host to request a graceful shutdown of the Windows system. To do this, either run `virtio-win-guest-tools.exe` or `guest-agent\qemu-ga-x86_64.msi`. You can confirm the guest agent was successfully installed by running `Get-Service QEMU-GA` within a PowerShell window. The output should resemble:

```
Status   Name               DisplayName
------   ----               -----------
Running  QEMU-GA            QEMU Guest Agent
```

You can then test whether the host GNU/Linux system can communicate with Windows via `QEMU Guest Agent` by running `virsh qemu-agent-command RDPWindows '{"execute":"guest-get-osinfo"}' --pretty`. The output should resemble:

```json
{
  "return": {
    "name": "Microsoft Windows",
    "kernel-release": "26100",
    "version": "Microsoft Windows 11",
    "variant": "client",
    "pretty-name": "Windows 10 Pro",
    "version-id": "11",
    "variant-id": "client",
    "kernel-version": "10.0",
    "machine": "x86_64",
    "id": "mswindows"
  }
}
```

Next, you will need to make some registry changes to enable RDP Applications to run on the system. Start by downloading the [RDPApps.reg](../oem/RDPApps.reg) file, right-clicking on the `Raw` button, and clicking on `Save target as`. Repeat the same thing for the [install.bat](../oem/install.bat) and the [NetProfileCleanup.ps1](../oem/NetProfileCleanup.ps1). **Do not download the Container.reg.**

<p align="center">
    <img src="./libvirt_images/26.png" width="700px"/>
</p>

Once you have downloaded all three files, right-click the install.bat and select "Run as administrator".

<p align="center">
    <img src="./libvirt_images/27.png" width="700px"/>
</p>

Rename the Windows virtual machine so that WinApps can locate it by navigating to the start menu and typing `About` to bring up the `About your PC` settings.

<p align="center">
    <img src="./libvirt_images/28.png" width="700px"/>
</p>

Scroll down and click on `Rename this PC`.

<p align="center">
    <img src="./libvirt_images/29.png" width="700px"/>
</p>

Rename the PC to `RDPWindows`, but **DO NOT** restart the virtual machine.

<p align="center">
    <img src="./libvirt_images/30.png" width="700px"/>
</p>

Scroll down to `Remote Desktop`, and enable `Enable Remote Desktop`.

<p align="center">
    <img src="./libvirt_images/31.png" width="700px"/>
</p>

At this point, you will need to restart the Windows virtual machine.

## (Optional) Configuring a Static IP Address
1. Identify the Windows MAC address.
    ```bash
    virsh dumpxml "RDPWindows" | grep "mac address"
    ```

2. Edit the virtual network configuration.
    1. Identify the correct network name.
        ```bash
        virsh net-list # Will likely return "default"
        ```

    2. Edit the configuration file.
        ```bash
        virsh net-edit "default" # Replace "default" with the appropriate network name if different
        ```

    3. Update the `<dhcp>` section in the configuration file using the MAC address you obtained earlier. In the below example, "RDPWindows" has MAC address "df:87:4c:75:e5:fb" and is assigned the static IP address "192.168.122.2".
        ```xml
        <dhcp>
          <range start="192.168.122.2" end="192.168.122.254"/>
          <host mac="df:87:4c:75:e5:fb" name="RDPWindows" ip="192.168.122.2"/>
          <host mac="53:45:6b:de:a0:7b" name="Debian" ip="192.168.122.3"/>
          <host mac="7d:62:4f:59:ef:f5" name="FreeBSD" ip="192.168.122.4"/>
        </dhcp>
        ```

    4. Restart the virtual network.
        ```bash
        virsh net-destroy "default" # Replace with the correct name on your system
        virsh net-start "default" # Replace with the correct name on your system
        ```

    5. Reboot Windows.

## Installing Windows Software and Configuring WinApps
You may now proceed to install other applications like 'Microsoft 365', 'Adobe Creative Cloud' or any other applications you would like to use through WinApps.

Finally, restart the virtual machine, but **DO NOT** log in. Close the virtual machine viewer and proceed to run the WinApps installation.

```bash
bash <(curl https://raw.githubusercontent.com/winapps-org/winapps/main/setup.sh)
```

You can search Windows VM for Advanced System Properties and change Performance Settings. And configure pagefile.

</details>

<details>
<summary>Step 2: Run the WinApps Installer</summary>

With Windows still powered on, run the WinApps installer.

```bash
bash <(curl https://raw.githubusercontent.com/winapps-org/winapps/main/setup.sh)
```

Once WinApps is installed, a list of additional arguments can be accessed by running `winapps-setup --help`.

<img src="./winapps_installer_images/installer.gif" width=1898 alt="WinApps Installer Animation.">
</details>

<details>
<summary>Post Install</summary>

# Adding Additional Pre-defined Applications
Adding your own applications with custom icons and MIME types to the installer is easy. Simply copy one of the application configurations in the `apps` folder located within the WinApps repository, and:
1. Modify the name and variables to reflect the appropriate/desired values for your application.
2. Replace `icon.svg` with an SVG for your application (ensuring the icon is appropriately licensed).
3. Remove and reinstall WinApps.
4. Submit a pull request to add your application to WinApps as an officially supported application once you have tested and verified your configuration (optional, but encouraged).

# Running Applications Manually
WinApps offers a manual mode for running applications that were not configured by the WinApps installer. This is completed with the `manual` flag. Executables that are in the Windows PATH do not require full path definition.

```bash
winapps manual "C:\my\directory\executableNotInPath.exe"
winapps manual executableInPath.exe
```

# Updating WinApps
The installer can be run multiple times. To update your installation of WinApps:
1. Run the WinApps installer to remove WinApps from your system.
2. Pull the latest changes from the WinApps GitHub repository.
3. Re-install WinApps using the WinApps installer by running `winapps-setup`.

</details>
