<p align="center">

![Banner Dark](icons/banner_dark.svg#gh-dark-mode-only)
![Banner Light](icons/banner_light.svg#gh-light-mode-only)

</p>

---


<p><img width="700"
        src="./icons/banner_dark.svg#gh-dark-mode-only"
        alt=""/></p>
<p><img width="700"
        src="./icons/banner_light.svg#gh-light-mode-only"
        alt=""/></p>
<hr>

Run Windows applications (including [Microsoft 365](https://www.microsoft365.com/) and [Adobe Creative Cloud](https://www.adobe.com/creativecloud.html)) on GNU/Linux with `KDE Plasma`, `GNOME` or `XFCE`, integrated seamlessly as if they were native to the OS.

<p><img src="docs/readme_images/demo.png"
        width=1920
        alt="WinApps Demonstration."></p>

## Underlying Mechanism
WinApps works by:
1. Running Windows in a `Docker`, `Podman` or `libvirt` virtual machine.
2. Querying Windows for all installed applications.
3. Creating shortcuts to selected Windows applications on the host GNU/Linux OS.
4. Using [`FreeRDP`](https://www.freerdp.com/) as a backend to seamlessly render Windows applications alongside GNU/Linux applications.

## Installaiton
 For a complete Installation guide, please reffer to the [INSTALL.md](docs/INSTALL.md)

## Additional Features
- The GNU/Linux `/home` directory is accessible within Windows via the `\\tsclient\home` mount.
- Integration with `Nautilus`, allowing you to right-click files to open them with specific Windows applications based on the file MIME type.
- The [official taskbar widget](https://github.com/winapps-org/WinApps-Launcher) enables seamless administration of the Windows subsystem and offers an easy way to launch Windows applications.

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
        <!-- Adobe Acrobat Pro -->
        <td>
            <img src="apps/acrobat-x-pro/icon.svg" width="100">
        </td>
        <td>
            <b>Adobe Acrobat Pro</b><br>
            (X)<br>
            <i><a href="https://commons.wikimedia.org/wiki/File:Adobe_Acrobat_DC_logo_2020.svg">Icon</a> in the Public Domain.</i>
        </td>
        <!-- Adobe After Effects -->
        <td>
            <img src="apps/aftereffects-cc/icon.svg" width="100">
        </td>
        <td>
            <b>Adobe After Effects</b><br>
            (CC)<br>
            <i><a href="https://commons.wikimedia.org/wiki/File:Adobe_After_Effects_CC_icon.svg">Icon</a> in the Public Domain.</i>
        </td>
    </tr>
    <tr>
        <!-- Adobe Audition -->
        <td>
            <img src="apps/audition-cc/icon.svg" width="100">
        </td>
        <td>
            <b>Adobe Audition</b><br>
            (CC)<br>
            <i><a href="https://en.m.wikipedia.org/wiki/File:Adobe_Audition_CC_icon_%282020%29.svg">Icon</a> in the Public Domain.</i>
        </td>
        <!-- Adobe Bridge -->
        <td>
            <img src="apps/bridge-cs6/icon.svg" width="100">
        </td>
        <td>
            <b>Adobe Bridge</b><br>
            (CS6, CC)<br>
            <i><a href="https://en.m.wikipedia.org/wiki/File:Adobe_Bridge_CC_icon.svg">Icon</a> in the Public Domain.</i>
        </td>
    </tr>
    <tr>
        <!-- Adobe Creative Cloud -->
        <td>
            <img src="apps/adobe-cc/icon.svg" width="100">
        </td>
        <td>
            <b>Adobe Creative Cloud</b><br>
            (CC)<br>
            <i><a href="https://iconduck.com/icons/240218/adobe-creative-cloud">Icon</a> under <a href="https://iconduck.com/licenses/mit">MIT license</a>.</i>
        </td>
        <!-- Adobe Illustrator -->
        <td>
            <img src="apps/illustrator-cc/icon.svg" width="100">
        </td>
        <td>
            <b>Adobe Illustrator</b><br>
            (CC)<br>
            <i><a href="https://commons.wikimedia.org/wiki/File:Adobe_Illustrator_CC_icon.svg">Icon</a> in the Public Domain.</i>
        </td>
    </tr>
    <tr>
        <!-- Adobe InDesign -->
        <td>
            <img src="apps/indesign-cc/icon.svg" width="100">
        </td>
        <td>
            <b>Adobe InDesign</b><br>
            (CC)<br>
            <i><a href="https://commons.wikimedia.org/wiki/File:Adobe_InDesign_CC_icon.svg">Icon</a> in the Public Domain.</i>
        </td>
        <!-- Adobe Lightroom -->
        <td>
            <img src="apps/lightroom-cc/icon.svg" width="100">
        </td>
        <td>
            <b>Adobe Lightroom</b><br>
            (CC)<br>
            <i><a href="https://commons.wikimedia.org/wiki/File:Adobe_Photoshop_Lightroom_CC_logo.svg">Icon</a> in the Public Domain.</i>
        </td>
    </tr>
    <tr>
        <!-- Adobe Photoshop -->
        <td>
            <img src="apps/photoshop-cc/icon.svg" width="100">
        </td>
        <td>
            <b>Adobe Photoshop</b><br>
            (CS6, CC, 2022)<br>
            <i><a href="https://commons.wikimedia.org/wiki/File:Adobe_Photoshop_CC_icon.svg">Icon</a> in the Public Domain.</i>
        </td>
        <!-- Command Prompt -->
        <td>
            <img src="apps/cmd/icon.svg" width="100">
        </td>
        <td>
            <b>Command Prompt</b><br>
            (cmd.exe)<br>
            <i><a href="https://github.com/microsoft/terminal/blob/main/res/terminal/Terminal.svg">Icon</a> under <a href="https://github.com/microsoft/terminal/blob/main/LICENSE">MIT license</a>.</i>
        </td>
    </tr>
    <tr>
        <!-- File Explorer -->
        <td>
            <img src="apps/explorer/icon.svg" width="100">
        </td>
        <td>
            <b>File Explorer</b><br>
            (Windows Explorer)<br>
            <i><a href="https://commons.wikimedia.org/wiki/File:Windows_Explorer.svg">Icon</a> in the Public Domain.</i>
        </td>
        <!-- Internet Explorer -->
        <td>
            <img src="apps/iexplorer/icon.svg" width="100">
        </td>
        <td>
            <b>Internet Explorer</b><br>
            (11)<br>
            <i><a href="https://commons.wikimedia.org/wiki/File:Internet_Explorer_10%2B11_logo.svg">Icon</a> in the Public Domain.</i>
        </td>
    </tr>
    <tr>
         <!-- Microsoft Access -->
        <td>
            <img src="apps/access/icon.svg" width="100">
        </td>
        <td>
            <b>Microsoft Access</b><br>
            (2016, 2019, o365)<br>
            <i><a href="https://commons.wikimedia.org/wiki/File:Microsoft_Office_Access_(2019-present).svg">Icon</a> in the Public Domain.</i>
        </td>
        <!-- Microsoft Excel -->
        <td>
            <img src="apps/excel/icon.svg" width="100">
        </td>
        <td>
            <b>Microsoft Excel</b><br>
            (2016, 2019, o365)<br>
            <i><a href="https://en.m.wikipedia.org/wiki/File:Microsoft_Office_Excel_(2019%E2%80%93present).svg">Icon</a> in the Public Domain.</i>
        </td>
    </tr>
    <tr>
        <!-- Microsoft Word -->
        <td>
            <img src="apps/word/icon.svg" width="100">
        </td>
        <td>
            <b>Microsoft Word</b><br>
            (2016, 2019, o365)<br>
            <i><a href="https://en.m.wikipedia.org/wiki/File:Microsoft_Office_Word_(2019%E2%80%93present).svg">Icon</a> in the Public Domain.</i>
        </td>
        <!-- Microsoft OneNote -->
        <td>
            <img src="apps/onenote/icon.svg" width="100">
        </td>
        <td>
            <b>Microsoft OneNote</b><br>
            (2016, 2019, o365)<br>
            <i><a href="https://en.m.wikipedia.org/wiki/File:Microsoft_Office_OneNote_(2019%E2%80%93present).svg">Icon</a> in the Public Domain.</i>
        </td>
    </tr>
    <tr>
        <!-- Microsoft Outlook -->
        <td>
            <img src="apps/outlook/icon.svg" width="100">
        </td>
        <td>
            <b>Microsoft Outlook</b><br>
            (2016, 2019, o365)<br>
            <i><a href="https://en.m.wikipedia.org/wiki/File:Microsoft_Office_Outlook_(2018%E2%80%93present).svg">Icon</a> in the Public Domain.</i>
        </td>
        <!-- Microsoft PowerPoint -->
        <td>
            <img src="apps/powerpoint/icon.svg" width="100">
        </td>
        <td>
            <b>Microsoft PowerPoint</b><br>
            (2016, 2019, o365)<br>
            <i><a href="https://en.m.wikipedia.org/wiki/File:Microsoft_Office_PowerPoint_(2019%E2%80%93present).svg">Icon</a> in the Public Domain.</i>
            </td>
    </tr>
    <tr>
        <!-- Microsoft Publisher -->
        <td>
            <img src="apps/publisher/icon.svg" width="100">
        </td>
        <td>
            <b>Microsoft Publisher</b><br>
            (2016, 2019, o365)<br>
            <i><a href="https://en.m.wikipedia.org/wiki/File:Microsoft_Office_Publisher_(2019-present).svg">Icon</a> in the Public Domain.</i>
        </td>
        <!-- Microsoft Visio -->
        <td>
            <img src="apps/visio/icon.svg" width="100">
        </td>
        <td>
            <b>Microsoft Visio</b><br>
            (Standard/Pro. 2021, Plan 2)<br>
            <i><a href="https://en.m.wikipedia.org/wiki/File:Microsoft_Office_Visio_(2019).svg">Icon</a> in the Public Domain.</i>
        </td>
    </tr>
    <tr>
        <!-- Microsoft Project -->
        <td>
            <img src="apps/project/icon.svg" width="100">
        </td>
        <td>
            <b>Microsoft Project</b><br>
            (Standard/Pro. 2021, Plan 3/5)<br>
            <i><a href="https://en.m.wikipedia.org/wiki/File:Microsoft_Project_(2019–present).svg">Icon</a> in the Public Domain.</i>
        </td>
        <!-- Microsoft Visual Studio -->
        <td>
            <img src="apps/visual-studio-pro/icon.svg" width="100">
        </td>
        <td>
            <b>Microsoft Visual Studio</b><br>
            (Comm./Pro./Ent. 2022)<br>
            <i><a href="https://en.m.wikipedia.org/wiki/File:Visual_Studio_Icon_2022.svg">Icon</a> in the Public Domain.</i>
        </td>
    </tr>
    <tr>
        <!-- mIRC -->
        <td>
            <img src="apps/mirc/icon.svg" width="100">
        </td>
        <td>
            <b>mIRC</b><br>
            <i><a href="https://en.wikipedia.org/wiki/MIRC#/media/File:Mircnewlogo.png">Icon</a> in the Public Domain.</i>
        </td>
        <!-- PowerShell -->
        <td>
            <img src="apps/powershell/icon.svg" width="100">
        </td>
        <td>
            <b>PowerShell</b><br>
            <i><a href="https://iconduck.com/icons/102322/file-type-powershell">Icon</a> under <a href="https://iconduck.com/licenses/mit">MIT license</a>.</i>
        </td>
    </tr>
    <tr>
        <!-- Windows -->
        <td>
            <img src="icons/windows.svg" width="100">
        </td>
        <td>
            <b>Windows</b><br>
            (Full RDP Session)<br>
            <i><a href="url">Icon</a> in the Public Domain.</i>
        </td>
    </tr>
</table>

## Star History
<a href="https://star-history.com/#winapps-org/winapps&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=winapps-org/winapps&type=Date&theme=dark"/>
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=winapps-org/winapps&type=Date"/>
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=winapps-org/winapps&type=Date"/>
 </picture>
</a>
