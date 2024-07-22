# Creating a Windows VM in `Docker` or `Podman`
Although WinApps supports using `QEMU+KVM+libvirt` as a backend for running Windows virtual machines, it is recommended to use `Docker` or `Podman`. These backends automate the setup process, eliminating the need for manual configuration and optimisation of the Windows virtual machine.

> [!IMPORTANT]
> Running a Windows virtual machine using `Docker` or `Podman` as a backend is only possible on GNU/Linux systems. This is due to the necessity of kernel interfaces, such as the KVM hypervisor, for achieving acceptable performance. The performance of the virtual machine can vary based on the version of the Linux kernel, with newer releases generally offering better performance.

> [!IMPORTANT]
> WinApps does NOT officially support versions of Windows prior to Windows 10. Despite this, it may be possible to achieve a successful installation with some additional experimentation. If you find a way to achieve this, please share your solution through a pull request for the benefit of other users.

## `Docker`
### Installation
You can find a guide for installing `Docker Engine` [here](https://docs.docker.com/engine/install/).

### Setup `Docker` Container
WinApps utilises `docker compose` to configure Windows VMs.

> [!IMPORTANT]
> The [`compose.yaml`](https://github.com/winapps-org/winapps/blob/main/compose.yaml) file located within the root directory of the WinApps repository must be manually copied to `~/.config/winapps/compose.yaml`.

Prior to installing Windows, you can modify the RAM and number of CPU cores available to the Windows VM by changing `RAM_SIZE` and `CPU_CORES` within `compose.yaml`.

It is also possible to specify the version of Windows you wish to install within `compose.yaml` by modifying `VERSION`.

> [!NOTE]
> WinApps uses a stripped-down Windows installation by default. Although this is recommended, you can request a stock Windows installation by changing `VERSION` to one of the versions listed in the README of the [original GitHub repository](https://github.com/dockur/windows).

Please refer to the [original GitHub repository](https://github.com/dockur/windows) for more information on additional configuration options.

### Installing Windows
You can initiate the Windows installation using `docker compose`.
```bash
docker compose --file ~/.config/winapps/compose.yaml up
```

You can then access the Windows virtual machine via a VNC connection to complete the Windows setup by navigating to http://127.0.0.1:8006 in your web browser.

### Installing WinApps
`Docker` simplifies the WinApps installation process by eliminating the need for any additional configuration of the Windows virtual machine. Once the Windows virtual machine is up and running, you can directly launch the WinApps installer, which should automatically detect and interface with Windows.

> [!NOTE]
> Since no Windows user password is set by default, Windows may automatically log in, which may cause the WinApps installation to fail due to complications establishing an RDP connection. To avoid this issue, please use the VNC connection to ensure that the Windows user is logged out before starting the WinApps installation.

```bash
./installer.sh
```

### Changing `compose.yaml`
Changes require the Windows virtual machine to be removed and re-created using the updated `compose.yaml`. This should __NOT__ affect your data.

```bash
docker compose --file ~/.config/winapps/compose.yaml down # Stop and remove the existing Windows virtual machine.
rm ~/.config/freerdp/server/127.0.0.1_3389.pem # Remove the existing FreeRDP certificate (a new certificate will be created automatically when connecting to the new virtual machine for the first time).
docker compose --file ~/.config/winapps/compose.yaml up # Re-create the virtual machine with the updated configuration.
```

### Subsequent Use
```bash
docker compose --file ~/.config/winapps/compose.yaml start # Power on the Windows VM
docker compose --file ~/.config/winapps/compose.yaml pause # Pause the Windows VM
docker compose --file ~/.config/winapps/compose.yaml unpause # Resume the Windows VM
docker compose --file ~/.config/winapps/compose.yaml restart # Restart the Windows VM
docker compose --file ~/.config/winapps/compose.yaml stop # Gracefully shut down the Windows VM
docker compose --file ~/.config/winapps/compose.yaml kill # Force shut down the Windows VM
```

## `Podman`
### Installation
1. Install `Podman` using [this guide](https://podman.io/docs/installation).
2. Install `podman-compose` using [this guide](https://github.com/containers/podman-compose?tab=readme-ov-file#installation).

### Setup `Podman` Container
Please follow the [`docker` instructions](#setup-docker-container).

> [!NOTE]
> Ensure `WAFLAVOR` is set to `"podman"` in `~/.config/winapps/winapps.conf`.

### Installing Windows
You can initiate the Windows installation using `podman-compose`.
```bash
podman-compose --file ~/.config/winapps/compose.yaml up
```

You can then access the Windows virtual machine via a VNC connection to complete the Windows setup by navigating to http://127.0.0.1:8006 in your web browser.

### Installing WinApps
Please follow the [`docker` instructions](#installing-winapps).

### Changing `compose.yaml`
Please follow the [`docker` instructions](#changing-composeyaml).

### Subsequent Use
```bash
podman-compose --file ~/.config/winapps/compose.yaml start # Power on the Windows VM
podman-compose --file ~/.config/winapps/compose.yaml pause # Pause the Windows VM
podman-compose --file ~/.config/winapps/compose.yaml unpause # Resume the Windows VM
podman-compose --file ~/.config/winapps/compose.yaml restart # Restart the Windows VM
podman-compose --file ~/.config/winapps/compose.yaml stop # Gracefully shut down the Windows VM
podman-compose --file ~/.config/winapps/compose.yaml kill # Force shut down the Windows VM
```
