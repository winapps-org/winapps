# WinApps
*The WinApps project, forked from Fmstrat's [original repository](https://github.com/Fmstrat/winapps).*

Run Windows applications (including [Microsoft 365](https://www.microsoft365.com/) and [Adobe Creative Cloud](https://www.adobe.com/creativecloud.html)) on GNU+Linux with `KDE` or `GNOME`, integrated seamlessly as if they were native to the OS.

<img src="demo/demo.gif" width=1000 alt="WinApps Demonstration Animation.">

## Underlying Mechanism
WinApps works by:
1. Running Windows in a `Docker` or `libvirt + KVM/QEMU` virtual machine (deprecated).
2. Querying Windows for all installed applications.
3. Creating shortcuts to selected Windows applications on the host GNU/Linux OS.
4. Using [`FreeRDP`](https://www.freerdp.com/) as a backend to seamlessly render Windows applications alongside GNU/Linux applications.

## Additional Features
- The GNU/Linux `/home` directory is accessible within Windows via the `\\tsclient\home` mount.
- Integration with `Nautilus`, allowing you to right-click files to open them with specific Windows applications based on the file MIME type.

## Supported Applications
**WinApps supports <u>*ALL*</u> Windows applications.**

Universal application support is achieved by:
1. Scanning Windows for any officially supported applications (list below).
2. Scanning Windows for any other `.exe` files listed within the Windows Registry.

Officially supported applications benefit from high-resolution icons and pre-populated MIME types. This enables file managers to determine which Windows applications should open files based on file extensions. Icons for other detected applications are pulled from `.exe` files.

Contributing to the list of supported applications is encouraged through submission of pull requests! Please help us grow the WinApps community.

*Please note that the provided list of officially supported applications is community-driven. As such, some applications may not be tested and verified by the WinApps team.*

### Officially Supported Applications
<table cellpadding="10" cellspacing="0" border="0">
    <tr>
        <td><img src="apps/acrobat-x-pro/icon.svg" width="100"></td><td>Adobe Acrobat Pro<br>(X)</td>
        <td><img src="apps/aftereffects-cc/icon.svg" width="100"></td><td>Adobe After Effects<br>(CC)</td>
    </tr>
    <tr>
        <td><img src="apps/audition-cc/icon.svg" width="100"></td><td>Adobe Audition<br>(CC)</td>
        <td><img src="apps/bridge-cs6/icon.svg" width="100"></td><td>Adobe Bridge<br>(CS6, CC)</td>
    </tr>
    <tr>
        <td><img src="apps/adobe-cc/icon.svg" width="100"></td><td>Adobe Creative Cloud<br>(CC)</td>
        <td><img src="apps/illustrator-cc/icon.svg" width="100"></td><td>Adobe Illustrator<br>(CC)</td>
    </tr>
    <tr>
        <td><img src="apps/indesign-cc/icon.svg" width="100"></td><td>Adobe InDesign<br>(CC)</td>
        <td><img src="apps/lightroom-cc/icon.svg" width="100"></td><td>Adobe Lightroom<br>(CC)</td>
    </tr>
    <tr>
        <td><img src="apps/cmd/icon.svg" width="100"></td><td>Command Prompt<br>(cmd.exe)</td>
        <td><img src="apps/explorer/icon.svg" width="100"></td><td>Explorer<br>(File Manager)</td>
    </tr>
    <tr>
        <td><img src="apps/iexplorer/icon.svg" width="100"></td><td>Internet Explorer<br>(11)</td>
        <td><img src="apps/access/icon.svg" width="100"></td><td>Microsoft Access<br>(2016, 2019, o365)</td>
    </tr>
    <tr>
        <td><img src="apps/excel/icon.svg" width="100"></td><td>Microsoft Excel<br>(2016, 2019, o365)</td>
        <td><img src="apps/word/icon.svg" width="100"></td><td>Microsoft Word<br>(2016, 2019, o365)</td>
    </tr>
    <tr>
        <td><img src="apps/onenote/icon.svg" width="100"></td><td>Microsoft OneNote<br>(2016, 2019, o365)</td>
        <td><img src="apps/outlook/icon.svg" width="100"></td><td>Microsoft Outlook<br>(2016, 2019, o365)</td>
    </tr>
    <tr>
        <td><img src="apps/powerpoint/icon.svg" width="100"></td><td>Microsoft PowerPoint<br>(2016, 2019, o365)</td>
        <td><img src="apps/publisher/icon.svg" width="100"></td><td>Microsoft Publisher<br>(2016, 2019, o365)</td>
    </tr>
    <tr>
        <td><img src="apps/powershell/icon.svg" width="100"></td><td>PowerShell</td>
        <td><img src="icons/windows.svg" width="100"></td><td>Windows<br>(Full RDP session)</td>
    </tr>
</table>

## Installation
### Step 1: Configure a Windows VM
The optimal choice for running a Windows VM as a subsystem for WinApps is `Docker`. `Docker` facilitates automated installation processes while leveraging a `KVM/QEMU` backend. Despite continuing to provide documentation for configuring a Windows VM using `libvirt` and `virt-manager`, this method is now considered deprecated.

The following guides are available:
- [Creating a Windows VM with `Docker`](docs/docker.md)
- [Creating a Windows VM with `virt-manager`](docs/KVM.md) (Deprecated)

If you already have a Windows VM or server you wish to use with WinApps, you will need to merge `install/RDPApps.reg` into the Windows Registry.

### Step 2: Clone WinApps Repository and Dependencies
1. Clone the WinApps GitHub repository.
    ```bash
    git clone https://github.com/winapps-org/winapps.git && cd winapps
    ```

2. Install the required dependencies.
    - Debian/Ubuntu:
        ```bash
        sudo apt install -y dialog freerdp3-x11
        ```
    - Fedora/RHEL:
        ```bash
        sudo dnf install -y dialog freerdp
        ```
    - Arch Linux:
        ```bash
        sudo pacman -Syu --needed -y dialog freerdp
        ```
    - Gentoo Linux:
        ```bash
        sudo emerge --ask=n sys-libs/dialog net-misc/freerdp:3
        ```

Please note that WinApps requires `FreeRDP` version 3 or later. If not available for your distribution through your package manager, you can install the [Flatpak](https://flathub.org/apps/com.freerdp.FreeRDP).

```bash
flatpak install flathub com.freerdp.FreeRDP
sudo flatpak override --filesystem=home com.freerdp.FreeRDP # To use `+home-drive`
```

### Step 3: Create a WinApps Configuration File
Create a configuration file at `~/.config/winapps/winapps.conf` containing the following:
```bash
RDP_USER="MyWindowsUser"
RDP_PASS="MyWindowsPassword"
#RDP_DOMAIN="MYDOMAIN"
#RDP_IP="192.168.123.111"
#RDP_SCALE=100
#RDP_FLAGS=""
#MULTIMON="true"
#DEBUG="true"
#FREERDP_COMMAND="xfreerdp"
```

`RDP_USER` and `RDP_PASS` must correspond to a complete Windows user account and password, such as those created during Windows setup or for a domain user. User/PIN combinations are not valid for RDP access.

#### Configuration Options Explained
- When using a pre-existing non-KVM RDP server, you must use `RDP_IP` to specify the location of the Windows server.
- If running a Windows VM in KVM with NAT enabled, leave `RDP_IP` commented out and WinApps will auto-detect the local IP address for the VM.
- For domain users, you can uncomment and change `RDP_DOMAIN`.
- On high-resolution (UHD) displays, you can set `RDP_SCALE` to the scale you would like to use [100|140|160|180].
- To add flags to the FreeRDP call, such as `/audio-mode:1` to pass in a microphone, uncomment and use the `RDP_FLAGS` configuration option.
- For multi-monitor setups, you can try enabling `MULTIMON`. A FreeRDP bug may result in a black screen however, in which case you should revert this change.
- If you enable `DEBUG`, a log will be created on each application start in `~/.local/share/winapps/winapps.log`
- If using a system on which the FreeRDP command is not `xfreerdp`, the correct command can be specified using `FREERDP_COMMAND`.

### Step 4: Run the WinApps Installer
Run the WinApps installer.
```bash
./installer.sh
```

A list of supported additional arguments can be accessed by running `./installer.sh --help`.

<img src="demo/installer.gif" width=1000>

## Adding Additional Pre-defined Applications
Adding your own applications with custom icons and MIME types to the installer is easy. Simply copy one of the application configurations in the `apps` folder located within the WinApps repository, and:
1. Modify the name and variables to reflect the appropriate/desired values for your application.
2. Replace `icon.svg` with an SVG for your application (ensuring the icon is appropriately licensed).
3. Remove and reinstall WinApps.
4. (Optional, but strongly encouraged) Submit a pull request to add your application to WinApps as an officially supported application once you have tested your configuration files to verify functionality.

## Running Applications Manually
WinApps offers a manual mode for running applications that were not configured by the WinApps installer. This is completed with the `manual` flag. Executables that are in the Windows PATH do not require full path definition.

```bash
./bin/winapps manual "C:\my\directory\executableNotInPath.exe"
./bin/winapps manual executableInPath.exe
```

## Updating WinApps
The installer can be run multiple times. To update your installation of WinApps:
1. Run the WinApps installer to remove WinApps from your system.
2. Pull the latest changes from the WinApps GitHub repository.
3. Re-install WinApps using the WinApps installer.

## Shout-outs
Some icons used for the officially supported applications were sourced from:
- Fluent UI React - Icons under [MIT License](https://github.com/Fmstrat/fluent-ui-react/blob/master/LICENSE.md)
- Fluent UI - Icons under [MIT License](https://github.com/Fmstrat/fluentui/blob/master/LICENSE) with [restricted use](https://static2.sharepointonline.com/files/fabric/assets/microsoft_fabric_assets_license_agreement_nov_2019.pdf)
- PKief's VSCode Material Icon Theme - Icons under [MIT License](https://github.com/Fmstrat/vscode-material-icon-theme/blob/master/LICENSE.md)
- DiemenDesign's LibreICONS - Icons under [MIT License](https://github.com/Fmstrat/LibreICONS/blob/master/LICENSE)
