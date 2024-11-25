# Creating a Windows VM in `Docker` or `Podman`
Although WinApps supports using `QEMU+KVM+libvirt` as a backend for running Windows virtual machines, it is recommended to use `Docker` or `Podman`. These backends automate the setup process, eliminating the need for manual configuration and optimisation of the Windows virtual machine.

> [!IMPORTANT]
> Running a Windows virtual machine using `Docker` or `Podman` as a backend is only possible on GNU/Linux systems. This is due to the necessity of kernel interfaces, such as the KVM hypervisor, for achieving acceptable performance. The performance of the virtual machine can vary based on the version of the Linux kernel, with newer releases generally offering better performance.

> [!IMPORTANT]
> WinApps does __NOT__ officially support versions of Windows prior to Windows 10. Despite this, it may be possible to achieve a successful installation with some additional experimentation. If you find a way to achieve this, please share your solution through a pull request for the benefit of other users.

## `Docker`
### Installation
You can find a guide for installing `Docker Engine` [here](https://docs.docker.com/engine/install/).

### Setup `Docker` Container
WinApps utilises `docker compose` to configure Windows VMs. A template [`compose.yaml`](https://github.com/winapps-org/winapps/blob/main/compose.yaml) is provided.

Prior to installing Windows, you can modify the RAM and number of CPU cores available to the Windows VM by changing `RAM_SIZE` and `CPU_CORES` within `compose.yaml`.

It is also possible to specify the version of Windows you wish to install within `compose.yaml` by modifying `VERSION`.

> [!NOTE]
> WinApps uses a stripped-down Windows installation by default. Although this is recommended, you can request a stock Windows installation by changing `VERSION` to one of the versions listed in the README of the [original GitHub repository](https://github.com/dockur/windows).

Please refer to the [original GitHub repository](https://github.com/dockur/windows) for more information on additional configuration options.

### Installing Windows
You can initiate the Windows installation using `docker compose`.
```bash
cd winapps
docker compose --file ./compose.yaml up
```

You can then access the Windows virtual machine via a VNC connection to complete the Windows setup by navigating to http://127.0.0.1:8006 in your web browser.

After installing Windows, comment out the following lines in the `compose.yaml` file by prepending a '#':
- `- ./oem:/oem`
- `- /path/to/windows/install/media.iso:/custom.iso` (if relevant)

Then, copy this modified `compose.yaml` file to `~/.config/winapps/compose.yaml`.

```bash
cp ./compose.yaml ~/.config/winapps/compose.yaml
```

Finally, ensure the new configuration is applied by running the following:

```bash
docker compose --file ./compose.yaml down
docker compose --file ~/.config/winapps/compose.yaml up
```


### Changing `compose.yaml`
Changes to `compose.yaml` require the Windows virtual machine to be removed and re-created. This should __NOT__ affect your data.

```bash
# Stop and remove the existing Windows virtual machine.
docker compose --file ~/.config/winapps/compose.yaml down

# Remove the existing FreeRDP certificate (if required).
# Note: A new certificate will be created when connecting via RDP for the first time.
rm ~/.config/freerdp/server/127.0.0.1_3389.pem

# Re-create the virtual machine with the updated configuration.
docker compose --file ~/.config/winapps/compose.yaml up
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

> [!IMPORTANT]
> Ensure `WAFLAVOR` is set to `"podman"` in `~/.config/winapps/winapps.conf`.

### Installing Windows
You can initiate the Windows installation using `podman-compose`.
```bash
cd winapps
podman-compose --file ./compose.yaml up
```

You can then access the Windows virtual machine via a VNC connection to complete the Windows setup by navigating to http://127.0.0.1:8006 in your web browser.

After installing Windows, comment out the following lines in the `compose.yaml` file by prepending a '#':
- `- ./oem:/oem`
- `- /path/to/windows/install/media.iso:/custom.iso` (if relevant)

Then, copy this modified `compose.yaml` file to `~/.config/winapps/compose.yaml`.

```bash
cp ./compose.yaml ~/.config/winapps/compose.yaml
```

Finally, ensure the new configuration is applied by running the following:

```bash
podman-compose --file ./compose.yaml down
podman-compose --file ~/.config/winapps/compose.yaml up
```

### Changing `compose.yaml`
Changes to `compose.yaml` require the Windows virtual machine to be removed and re-created. This should __NOT__ affect your data.

```bash
# Stop and remove the existing Windows virtual machine.
podman-compose --file ~/.config/winapps/compose.yaml down

# Remove the existing FreeRDP certificate (if required).
# Note: A new certificate will be created when connecting via RDP for the first time.
rm ~/.config/freerdp/server/127.0.0.1_3389.pem

# Re-create the virtual machine with the updated configuration.
podman-compose --file ~/.config/winapps/compose.yaml up
```

### Subsequent Use
```bash
podman-compose --file ~/.config/winapps/compose.yaml start # Power on the Windows VM
podman-compose --file ~/.config/winapps/compose.yaml pause # Pause the Windows VM
podman-compose --file ~/.config/winapps/compose.yaml unpause # Resume the Windows VM
podman-compose --file ~/.config/winapps/compose.yaml restart # Restart the Windows VM
podman-compose --file ~/.config/winapps/compose.yaml stop # Gracefully shut down the Windows VM
podman-compose --file ~/.config/winapps/compose.yaml kill # Force shut down the Windows VM
```
