# Installation
<details open>
<summary>Step 1: Configure a Windows VM </summary>

Both `Docker` and `Podman` are recommended backends for running the Windows virtual machine, as they facilitate an automated Windows installation process. WinApps is also compatible with `libvirt`. While this method requires considerably more manual configuration, it also provides greater virtual machine customisation options. All three methods leverage the `KVM` hypervisor, ensuring excellent virtual machine performance. Ultimately, the choice of backend depends on your specific use case.

<details>
<summary>Creating a Windows VM with Docker or Podman</summary>

Although WinApps supports using `QEMU+KVM+libvirt` as a backend for running Windows virtual machines, it is recommended to use `Docker` or `Podman`. These backends automate the setup process, eliminating the need for manual configuration and optimisation of the Windows virtual machine.

> [!IMPORTANT]
> Running a Windows virtual machine using `Docker` or `Podman` as a backend is only possible on GNU/Linux systems. This is due to the necessity of kernel interfaces, such as the KVM hypervisor, for achieving acceptable performance. The performance of the virtual machine can vary based on the version of the Linux kernel, with newer releases generally offering better performance.

> [!IMPORTANT]
> WinApps does __NOT__ officially support versions of Windows prior to Windows 10. Despite this, it may be possible to achieve a successful installation with some additional experimentation. If you find a way to achieve this, please share your solution through a pull request for the benefit of other users.
> Possible setup instructions for Windows 10:
> - 'Professional', 'Enterprise' or 'Server' editions of Windows are required to run RDP applications. Windows 'Home' will __NOT__ suffice.
> - It is recommended to edit the initial `compose.yaml` file to keep your required username and password from the beginning.
> - It is recommended to not use `sudo` to force commands to run. Add your user to the relevant permissions group wherever possible.

## `Docker` Installation
You can find a full guide for installing `Docker Engine` and list of supported Linux distros [here](https://docs.docker.com/engine/install/).

> [!Note]
> If you don't see your Linux distro in list of supported platforms, you should install docker from [binaries](https://docs.docker.com/engine/install/binaries/)

### Setup `Docker` Container
WinApps utilises `docker compose` to configure Windows VMs. You can find Docker Compose Plugin installation guide [here](https://docs.docker.com/compose/install/linux/)

> [!Note]
> If you don't see your Linux distro in list of supported platforms, you should install Docker Compose Plugin [manually](https://docs.docker.com/compose/install/linux/#install-the-plugin-manually)

A template [`compose.yaml`](../compose.yaml) is provided by WinApps.

Prior to installing Windows, you can modify the RAM and number of CPU cores available to the Windows VM by changing `RAM_SIZE` and `CPU_CORES` within `compose.yaml`.
It is also possible to specify the version of Windows you wish to install within `compose.yaml` by modifying `VERSION`.

> [!Note]
> You need to give your user permission to use docker.sock. Plaes change `<user name or ID>` to your user name
> ```bash
> sudo setfacl --modify user:<user name or ID>:rw /var/run/docker.sock
> ```

#### Minimal compose.yaml setup
To start configuring it we need to clone git repository of WinApps. And edit compose.yaml. We will use `nano` for purposes of this guide, while you can use any text editor of your liking

```bash
git clone https://github.com/winapps-org/winapps.git
cd winapps
nano compose.yaml
```
>[!IMPORTANT]
>In `nano`
>Use arrow keys to move in text
>Use Ctrl+O to save file, you will be proposed to rename file
>Leave the name as it is and just press Enter
>Use Ctrl+X to close file.
>
>Now we are interested in VERSION, RAM_SIZE, CPU_CORES, DISK_SIZE, USERNAME, and PASSWORD
>Set VERSION to 11 or 10. This will change which windows docker needs to download. Windows 11 Professional or Windows 10 Proffesional.
>In RAM_SIZE and CPU_CORES set the value you are ready to give to VM. Please note it will be used in background, so no need to go all in.
>To see your RAM you can open another terminal and use:
>```bash
>free -h
>```
>For CPU Cores use:
>```bash
>nproc
>```
>In DISK_SIZE set ammount of disc space you expect to be used by apps you want to have.
>And finally we need to set USERNAME and PASSWORD. Set your own values here BUT they should not be empty or else you won't be able to login.


Please refer to the [original GitHub repository](https://github.com/dockur/windows?tab=readme-ov-file#faq-) for more information on additional configuration options.

> [!NOTE]
> If you want to undo all your changes and start from scratch, run the following. For `podman`, replace `docker compose` with `podman-compose`.
> ```bash
> docker compose down --rmi=all --volumes
> ```

### Installing Windows
> [!IMPORTANT]
> The iptables kernel module must be loaded for folder sharing with the host to work.
> Check that the output of this command isn't empty.
> ```bash
> lsmod | grep ip_tables; lsmod | grep iptable_nat
>```
>
> If the output of one of the previous command is empty, run
> ```bash
> echo -e "ip_tables\niptable_nat" | sudo tee /etc/modules-load.d/iptables.conf
> ```
> and reboot.

You can initiate the Windows installation using `docker compose`.
Make sure you are inside of winapps folder
```bash
cd ; cd winapps
docker compose --file ./compose.yaml up
```

> [!NOTE]
> If you encounter "Cannot connect to the Docker daemon". You need to start daemon
> ```bash
> sudo systemctl start docker
> ```
>
>You can then access the Windows virtual machine via a VNC connection to complete the Windows setup by navigating to http://127.0.0.1:8006 in your web browser.

### Changing `compose.yaml`
Changes to `compose.yaml` require the container to be removed and re-created. This should __NOT__ affect your data. This is done every time you want to change values. e.g. RAM_SIZE, add new drive, etc.

```bash
# Stop and remove the existing container.
docker compose --file ~/.config/winapps/compose.yaml down
```
```bash
# Remove the existing FreeRDP certificate (if required).
# Note: A new certificate will be created when connecting via RDP for the first time.
rm ~/.config/freerdp/server/127.0.0.1_3389.pem
```
```bash
# Re-create the container with the updated configuration.
# Add the -d flag at the end to run the container in the background.
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

> [!NOTE]
> #### Rootless `podman` containers
> If you are invoking podman as a user, your container will be "rootless". This can be desirable as a security feature. However, you may encounter an error about missing permissions to /dev/kvm as a consequence.
>
> For rootless podman to work, you need to add your user to the `kvm` group (depending on your distribution) to be able to access `/dev/kvm`. Make sure that you are using `crun` as your container runtime, not `runc`. Usually this is done by stopping all containers and (de-)installing the corresponding packages. Then either invoke podman-compose as `podman-compose --file ./compose.yaml --podman-create-args '--group-add keep-groups' up`. Or edit `compose.yaml` and uncomment the `group_add:` section at the end.

> [!IMPORTANT]
> Ensure `WAFLAVOR` is set to `"podman"` in `~/.config/winapps/winapps.conf`.

### Installing Windows
You can initiate the Windows installation using `podman-compose`.
```bash
cd ; cd winapps
podman-compose --file ./compose.yaml up
```

You can then access the Windows virtual machine via a VNC connection to complete the Windows setup by navigating to http://127.0.0.1:8006 in your web browser.

### Changing `compose.yaml`
Changes to `compose.yaml` require the container to be removed and re-created. This should __NOT__ affect your data.

```bash
# Stop and remove the existing container.
podman-compose --file ~/.config/winapps/compose.yaml down
```
```bash
# Remove the existing FreeRDP certificate (if required).
# Note: A new certificate will be created when connecting via RDP for the first time.
rm ~/.config/freerdp/server/127.0.0.1_3389.pem
```
```bash
# Re-create the container with the updated configuration.
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

</details>

<details>
<summary>Creating a Windosw VM with libvirt</summary>

## Understanding The Virtualisation Stack
This method of configuring a Windows virtual machine for use with WinApps is significantly more involved than utilising `Docker` or `Podman`. Nevertheless, expert users may prefer this method due to its greater flexibility and wider range of customisation options.

Before beginning, it is important to have a basic understanding of the various components involved in this particular method.

1. `QEMU` is a FOSS emulator that performs hardware virtualisation, enabling operating systems and applications designed for one architecture (e.g., aarch64) to run on systems with differing architectures (e.g., amd64). When used in conjunction with `KVM`, it can run virtual machines at near-native speed (provided the guest virtual machine matches the host architecture) by utilising hardware extensions like Intel VT-x or AMD-V.
2. `KVM` is a Linux kernel module that enables the kernel to function as a type-1 hypervisor. `KVM` runs directly on the underlying hardware (as opposed to on top of the GNU/Linux host OS). For many workloads, the performance overhead is minimal, often in the range of 2-5%. `KVM` requires a CPU with hardware virtualisation extensions.
3. `libvirt` is an open-source API, daemon, and management tool for orchestrating platform virtualisation. It provides a consistent and stable interface for managing various virtualisation technologies, including `KVM` and `QEMU` (as well as others). `libvirt` offers a wide range of functionality to control the lifecycle of virtual machines, storage, networks, and interfaces, making it easier to interact with virtualisation capabilities programmatically or via command-line tools.
4. `virt-manager` (Virtual Machine Manager) is a GUI desktop application that provides an easy-to-use interface for creating, configuring and controlling virtual machines. `virt-manager`  utilises `libvirt` as a backend.

Together, these components form a powerful and flexible virtualization stack, with `KVM` providing low-level kernel-based virtualisation capabilities, `QEMU` providing high-level userspace-based virtualisation functionality, `libvirt` managing the resources and `virt-manager` offering an intuitive graphical management interface.

<p align="center">
    <img src="./libvirt_images/Virtualisation_Stack.svg" width="500px"/>
</p>

## Prerequisites
1. Ensure your CPU supports hardware virtualisation extensions by [reading this article](https://wiki.archlinux.org/title/KVM).

2. Install all dependencies by installing `virt-manager`. This will ensure that your package manager automatically installs all the necessary components.
    ```bash
    sudo apt install virt-manager # Debian/Ubuntu
    sudo dnf install virt-manager # Fedora/RHEL
    sudo pacman -S virt-manager # Arch Linux
    sudo emerge app-emulation/virt-manager # Gentoo Linux
    ```

3. Configure `libvirt` to use the 'system' URI by adding the line `LIBVIRT_DEFAULT_URI="qemu:///system"` to your preferred shell profile file (e.g., `.bashrc`, `.zshrc`, etc.).
    ```bash
    echo 'export LIBVIRT_DEFAULT_URI="qemu:///system"' >> ~/.bashrc
    ```

> [!NOTE]
> WinApps may not read your shell's configuration. If you're having issues getting the installer to detect your VM, try adding
> `LIBVIRT_DEFAULT_URI="qemu:///system"` to your `/etc/environment` like:
> ```bash
> echo 'LIBVIRT_DEFAULT_URI="qemu:///system"' | sudo tee -a /etc/environment
> ```
> Thanks to imoize for pointing this out: https://github.com/winapps-org/winapps/issues/310#issuecomment-2505348088

4. Configure rootless `libvirt` and `kvm` by adding your user to groups of the same name.
    ``` bash
    sudo usermod -a -G kvm $(id -un) # Add the user to the 'kvm' group.
    sudo usermod -a -G libvirt $(id -un) # Add the user to the 'libvirt' group.
    sudo reboot # Reboot the system to ensure the user is added to the relevant groups.
    ```

    Note: Due to a known bug in `rpm-ostree`, which affects various distributions such as Silverblue, Bazzite, Bluefin, Kinoite, Aurora, UCore, and others, the commands provided earlier may not properly add your user to all required groups. If the `groups $USER` command does not show your user as being part of the necessary groups, you'll need to manually add these groups to `/etc/group` if they are present in `/usr/lib/group`.

    To resolve this:
    1. Identify which groups are missing from the output of `groups $USER`.
    2. Use the following snippet to add each missing group to `/etc/group`. Ensure you replace "kvm" with the name of the missing group.

        ```bash
        grep -E '^kvm:' /usr/lib/group | sudo tee -a /etc/group
        sudo usermod -aG kvm $USER
        ```

    3. Reboot your system to ensure that the user is correctly added to the relevant groups.

5. If relevant to your distribution, disable `AppArmor` for the `libvirt` daemon.
    ``` bash
    sudo ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/ # Disable AppArmor for the libvirt daemon by creating a symbolic link.
    ```

> [!NOTE]
> Systems with `SELinux` may also require security policy adjustments if virtual machine images are stored outside the default `/var/lib/libvirt/images` directory. Read [this guide](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/5/html/virtualization/sect-virtualization-security_for_virtualization-selinux_and_virtualization#sect-Virtualization-Security_for_virtualization-SELinux_and_virtualization) for more information.

6. Download a [Windows 10](https://www.microsoft.com/software-download/windows10ISO) or [Windows 11](https://www.microsoft.com/software-download/windows11) installation `.ISO` image.

> [!IMPORTANT]
> 'Professional', 'Enterprise' or 'Server' editions of Windows are required to run RDP applications. Windows 'Home' will NOT suffice.

7. Download [VirtIO drivers](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso) for the Windows virtual machine.

> [!NOTE]
> VirtIO drivers enhance system performance and minimize overhead by enabling the Windows virtual machine to use specialised network and disk device drivers. These drivers are aware that they are operating inside a virtual machine, and cooperate with the hypervisor. This approach eliminates the need for the hypervisor to emulate physical hardware devices, which is a computationally expensive process. This setup allows guests to achieve high-performance network and disk operations, leveraging the benefits of paravirtualisation.
> The above link contains the latest release of the `VirtIO` drivers for Windows, compiled and signed by Red Hat. Older versions of the `VirtIO` drivers can be downloaded [here](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/?C=M;O=D).
> You can read more about `VirtIO` [here](https://wiki.libvirt.org/Virtio.html) and [here](https://developer.ibm.com/articles/l-virtio/).

## Creating a Windows VM
1. Open `virt-manager`.

> [!NOTE]
> The name given to the application can vary between GNU/Linux distributions (e.g., 'Virtual Machines', 'Virtual Machine Manager', etc.)

<p align="center">
    <img src="./libvirt_images/00.png" width="500px"/>
</p>

2. Navigate to `Edit`&rarr;`Preferences`. Ensure `Enable XML editing` is enabled, then click the `Close` button.

<p align="center">
    <img src="./libvirt_images/01.png" width="500px"/>
</p>

3. Create a new virtual machine by clicking the `+` button.

<p align="center">
    <img src="./libvirt_images/02.png" width="500px" alt="Creating a new virtual machine in 'virt-manager'"/>
</p>

4. Choose `Local install media` and click `Forward`.

<p align="center">
    <img src="./libvirt_images/03.png" width="500px"/>
</p>

5. Select the location of your Windows 10 or 11 `.ISO` by clicking `Browse...` and `Browse Local`. Ensure `Automatically detect from the installation media / source` is enabled.

<p align="center">
    <img src="./libvirt_images/04_1.png" width="500px"/>
    <img src="./libvirt_images/04_2.png" width="700px"/>
</p>

6. Configure the RAM and CPU cores allocated to the Windows virtual machine. We recommend `2` CPUs and `4096MB` of RAM. We will use the `VirtIO` Memory Ballooning service, which means the virtual machine can use up to `4096MB` of memory, but it will only consume this amount if necessary.

<p align="center">
    <img src="./libvirt_images/05.png" width="500px"/>
</p>

7. Configure the virtual disk by setting its maximum size. While this size represents the largest it can grow to, the disk will only use this space as needed.

<p align="center">
    <img src="./libvirt_images/06.png" width="500px"/>
</p>

8. Name your virtual machine `RDPWindows` to ensure it is recognized by WinApps, and select the option to `Customize configuration before installation`.

<p align="center">
    <img src="./libvirt_images/07.png" width="500px"/>
</p>

> [!NOTE]
> A name other than `RDPWindows` can be used if `VM_NAME` is set in `~/.config/winapps/winapps.conf`.

9. After clicking `Finish`, select `Copy host CPU configuration` under 'CPUs', and then click `Apply`.

> [!NOTE]
> Sometimes this feature gets disabled after installing Windows. Make sure to check and re-enable this option after the installation is complete.

<p align="center">
    <img src="./libvirt_images/08.png" width="700px"/>
</p>

10. (Optional) Assign specific physical CPU cores to the virtual machine. This can improve performance by reducing context switching and ensuring that the virtual machine's workload consistently uses the same cores, leading to better CPU cache utilisation.
    1. Run `lscpu -e` to determine which L1, L2 and L3 caches are associated with which CPU cores.

        Example 1 (Intel 11th Gen Core i7-1185G7):
        ```
        CPU NODE SOCKET CORE L1d:L1i:L2:L3 ONLINE    MAXMHZ   MINMHZ
          0    0      0    0 0:0:0:0          yes 4800.0000 400.0000
          1    0      0    1 1:1:1:0          yes 4800.0000 400.0000
          2    0      0    2 2:2:2:0          yes 4800.0000 400.0000
          3    0      0    3 3:3:3:0          yes 4800.0000 400.0000
          4    0      0    0 0:0:0:0          yes 4800.0000 400.0000
          5    0      0    1 1:1:1:0          yes 4800.0000 400.0000
          6    0      0    2 2:2:2:0          yes 4800.0000 400.0000
          7    0      0    3 3:3:3:0          yes 4800.0000 400.0000
        ```

        - C<sub>0</sub> = T<sub>0</sub>+T<sub>4</sub> &rarr; L1<sub>0</sub>+L2<sub>0</sub>+L3<sub>0</sub>
        - C<sub>1</sub> = T<sub>1</sub>+T<sub>5</sub> &rarr; L1<sub>1</sub>+L2<sub>1</sub>+L3<sub>0</sub>
        - C<sub>2</sub> = T<sub>2</sub>+T<sub>6</sub> &rarr; L1<sub>2</sub>+L2<sub>2</sub>+L3<sub>0</sub>
        - C<sub>3</sub> = T<sub>3</sub>+T<sub>7</sub> &rarr; L1<sub>3</sub>+L2<sub>3</sub>+L3<sub>0</sub>

        Example 2 (AMD Ryzen 5 1600):
        ```
        CPU NODE SOCKET CORE L1d:L1i:L2:L3 ONLINE MAXMHZ    MINMHZ
        0   0    0      0    0:0:0:0       yes    3800.0000 1550.0000
        1   0    0      0    0:0:0:0       yes    3800.0000 1550.0000
        2   0    0      1    1:1:1:0       yes    3800.0000 1550.0000
        3   0    0      1    1:1:1:0       yes    3800.0000 1550.0000
        4   0    0      2    2:2:2:0       yes    3800.0000 1550.0000
        5   0    0      2    2:2:2:0       yes    3800.0000 1550.0000
        6   0    0      3    3:3:3:1       yes    3800.0000 1550.0000
        7   0    0      3    3:3:3:1       yes    3800.0000 1550.0000
        8   0    0      4    4:4:4:1       yes    3800.0000 1550.0000
        9   0    0      4    4:4:4:1       yes    3800.0000 1550.0000
        10  0    0      5    5:5:5:1       yes    3800.0000 1550.0000
        11  0    0      5    5:5:5:1       yes    3800.0000 1550.0000
        ```

        - C<sub>0</sub> = T<sub>0</sub>+T<sub>1</sub> &rarr; L1<sub>0</sub>+L2<sub>0</sub>+L3<sub>0</sub>
        - C<sub>1</sub> = T<sub>2</sub>+T<sub>3</sub> &rarr; L1<sub>1</sub>+L2<sub>1</sub>+L3<sub>0</sub>
        - C<sub>2</sub> = T<sub>4</sub>+T<sub>5</sub> &rarr; L1<sub>2</sub>+L2<sub>2</sub>+L3<sub>0</sub>
        - C<sub>3</sub> = T<sub>6</sub>+T<sub>7</sub> &rarr; L1<sub>3</sub>+L2<sub>3</sub>+L3<sub>1</sub>
        - C<sub>4</sub> = T<sub>8</sub>+T<sub>9</sub> &rarr; L1<sub>4</sub>+L2<sub>4</sub>+L3<sub>1</sub>
        - C<sub>5</sub> = T<sub>10</sub>+T<sub>11</sub> &rarr; L1<sub>5</sub>+L2<sub>5</sub>+L3<sub>1</sub>

    2. Select which CPU cores to 'pin'. You should aim to select a combination of CPU cores that minimises sharing of caches between Windows and GNU/Linux.

        Example 1:
        - CPU cores share the same singular L3 cache, so this cannot be optimised.
        - CPU cores utilise different L1 and L2 caches, so isolatng corresponding thread pairs will help improve performance.
        - Thus, if limiting the virtual machine to a maximum of 4 threads, there are 10 possible optimal configurations:
            - T<sub>0</sub>+T<sub>4</sub>
            - T<sub>1</sub>+T<sub>5</sub>
            - T<sub>2</sub>+T<sub>6</sub>
            - T<sub>3</sub>+T<sub>7</sub>
            - T<sub>0</sub>+T<sub>4</sub>+T<sub>1</sub>+T<sub>5</sub>
            - T<sub>0</sub>+T<sub>4</sub>+T<sub>2</sub>+T<sub>6</sub>
            - T<sub>0</sub>+T<sub>4</sub>+T<sub>3</sub>+T<sub>7</sub>
            - T<sub>1</sub>+T<sub>5</sub>+T<sub>2</sub>+T<sub>6</sub>
            - T<sub>1</sub>+T<sub>5</sub>+T<sub>3</sub>+T<sub>7</sub>
            - T<sub>2</sub>+T<sub>6</sub>+T<sub>3</sub>+T<sub>7</sub>

        Example 2:
        - Threads 0-5 utilise one L3 cache whereas threads 6-11 utilise a different L3 cache. Thus, one of these two sets of threads should be pinned to the virtual machine.
        - Pinning and isolating fewer than these (e.g. threads 8-11) would result in the host system making use of the L3 cache in threads 6 and 7, resulting in cache evictions and therefore bad performance.
        - Thus, there are only two possible optimal configurations:
            - T<sub>0</sub>+T<sub>1</sub>+T<sub>2</sub>+T<sub>3</sub>+T<sub>4</sub>+T<sub>5</sub>
            - T<sub>6</sub>+T<sub>7</sub>+T<sub>8</sub>+T<sub>9</sub>+T<sub>10</sub>+T<sub>11</sub>

    3. Prepare and add/modify the following to the `<vcpu>`, `<cputune>` and `<cpu>` sections, adjusting the values to match your selected threads.

        Example 1: The following selects 'T<sub>2</sub>+T<sub>6</sub>+T<sub>3</sub>+T<sub>7</sub>'.

        ```xml
        <vcpu placement="static">4</vcpu>
        <cputune>
            <vcpupin vcpu="0" cpuset="2"/>
            <vcpupin vcpu="1" cpuset="6"/>
            <vcpupin vcpu="2" cpuset="3"/>
            <vcpupin vcpu="3" cpuset="7"/>
        </cputune>
        <cpu mode="host-passthrough" check="none" migratable="on">
            <topology sockets="1" dies="1" clusters="1" cores="2" threads="2"/>
        </cpu>
        ```

        Example 2: The following selects 'T<sub>6</sub>+T<sub>7</sub>+T<sub>8</sub>+T<sub>9</sub>+T<sub>10</sub>+T<sub>11</sub>'.

        ```xml
        <vcpu placement="static">6</vcpu>
        <cputune>
            <vcpupin vcpu="0" cpuset="6"/>
            <vcpupin vcpu="1" cpuset="7"/>
            <vcpupin vcpu="2" cpuset="8"/>
            <vcpupin vcpu="3" cpuset="9"/>
            <vcpupin vcpu="4" cpuset="10"/>
            <vcpupin vcpu="5" cpuset="11"/>
        </cputune>
        <cpu mode="host-passthrough" check="none" migratable="on">
            <topology sockets="1" dies="1" clusters="1" cores="3" threads="2"/>
        </cpu>
        ```

> [!NOTE]
> More information on configuring CPU pinning can be found in [this excellent guide](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#CPU_pinning).

11. Navigate to the `XML` tab, and edit the `<clock>` section to disable all timers except for the hypervclock, thereby drastically reducing idle CPU usage. Once changed, click `Apply`.
    ```xml
    <clock offset='localtime'>
      <timer name='rtc' present='no' tickpolicy='catchup'/>
      <timer name='pit' present='no' tickpolicy='delay'/>
      <timer name='hpet' present='no'/>
      <timer name='kvmclock' present='no'/>
      <timer name='hypervclock' present='yes'/>
    </clock>
    ```

<p align="center">
    <img src="./libvirt_images/09.png" width="700px"/>
</p>

12. Enable Hyper-V enlightenments by adding the following to the `<hyperv>` section. Once changed, click `Apply`.

    ```xml
    <hyperv>
      <relaxed state='on'/>
      <vapic state='on'/>
      <spinlocks state='on' retries='8191'/>
      <vpindex state='on'/>
      <synic state='on'/>
      <stimer state='on'>
        <direct state='on'/>
      </stimer>
      <reset state='on'/>
      <frequencies state='on'/>
      <reenlightenment state='on'/>
      <tlbflush state='on'/>
      <ipi state='on'/>
    </hyperv>
    ```

> [!NOTE]
> Hyper-V enlightenments make Windows (and other Hyper-V guests) think they are running on top of a Hyper-V compatible hypervisor. This enables use of Hyper-V specific features, allowing `KVM` to implement paravirtualised interfaces for improved virtual machine performance.

13. Add the following XML snippet within the `<devices>` section to enable the GNU/Linux host to communicate with Windows using `QEMU Guest Agent`.

    ```xml
    <channel type='unix'>
      <source mode='bind'/>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='2'/>
    </channel>
    ```

14. In the 'Memory' section, set the `Current allocation` to the minimum amount of memory you want the virtual machine to use, with a recommended value of `1024MB`.

<p align="center">
    <img src="./libvirt_images/10.png" width="500px"/>
</p>

15. (Optional) Under `Boot Options`, enable `Start virtual machine on host boot up`.

<p align="center">
    <img src="./libvirt_images/11.png" width="500px"/>
</p>

16. Navigate to 'SATA Disk 1' and set the `Disk bus` type to `VirtIO`. This allows disk access to be paravirtualised, improving virtual machine performance.

<p align="center">
    <img src="./libvirt_images/12.png" width="500px"/>
</p>

17. Navigate to 'NIC' and set the `Device model` type to `virtio` to enable paravirtualised networking.

<p align="center">
    <img src="./libvirt_images/13.png" width="500px"/>
</p>

18. Click the `Add Hardware` button in the lower left, and choose `Storage`. For `Device type`, select `CDROM device` and choose the VirtIO driver `.ISO` you downloaded earlier. Click `Finish` to add the new CD-ROM device.

> [!IMPORTANT]
> If you skip this step, the Windows installer will fail to recognise and list the virtual hard drive you created earlier.

<p align="center">
    <img src="./libvirt_images/14.png" width="500px"/>
</p>

19. Click `Begin Installation` in the top left.

<p align="center">
    <img src="./libvirt_images/15.png" width="700px"/>
</p>

### Example `.XML` File
Below is an example `.XML` file that describes a Windows 11 virtual machine.

```xml
<domain type="kvm">
  <name>RDPWindows</name>
  <uuid>4d76e36e-c632-43e0-83c0-dc9f36c2823a</uuid>
  <metadata>
    <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
      <libosinfo:os id="http://microsoft.com/win/11"/>
    </libosinfo:libosinfo>
  </metadata>
  <memory unit="KiB">8388608</memory>
  <currentMemory unit="KiB">8388608</currentMemory>
  <vcpu placement="static">4</vcpu>
  <cputune>
    <vcpupin vcpu="0" cpuset="2"/>
    <vcpupin vcpu="1" cpuset="6"/>
    <vcpupin vcpu="2" cpuset="3"/>
    <vcpupin vcpu="3" cpuset="7"/>
  </cputune>
  <os firmware="efi">
    <type arch="x86_64" machine="pc-q35-8.1">hvm</type>
    <firmware>
      <feature enabled="yes" name="enrolled-keys"/>
      <feature enabled="yes" name="secure-boot"/>
    </firmware>
    <loader readonly="yes" secure="yes" type="pflash" format="qcow2">/usr/share/edk2/ovmf/OVMF_CODE_4M.secboot.qcow2</loader>
    <nvram template="/usr/share/edk2/ovmf/OVMF_VARS_4M.secboot.qcow2" format="qcow2">/var/lib/libvirt/qemu/nvram/RDPWindows_VARS.qcow2</nvram>
    <boot dev="hd"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <hyperv mode="custom">
      <relaxed state="on"/>
      <vapic state="on"/>
      <spinlocks state="on" retries="8191"/>
      <vpindex state="on"/>
      <synic state="on"/>
      <stimer state="on">
        <direct state="on"/>
      </stimer>
      <reset state="on"/>
      <frequencies state="on"/>
      <reenlightenment state="on"/>
      <tlbflush state="on"/>
      <ipi state="on"/>
    </hyperv>
    <vmport state="off"/>
    <smm state="on"/>
  </features>
  <cpu mode="host-passthrough" check="none" migratable="on">
    <topology sockets="1" dies="1" clusters="1" cores="2" threads="2"/>
  </cpu>
  <clock offset="localtime">
    <timer name="rtc" present="no" tickpolicy="catchup"/>
    <timer name="pit" present="no" tickpolicy="delay"/>
    <timer name="hpet" present="no"/>
    <timer name="kvmclock" present="no"/>
    <timer name="hypervclock" present="yes"/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled="no"/>
    <suspend-to-disk enabled="no"/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2" discard="unmap"/>
      <source file="/var/lib/libvirt/images/RDPWindows.qcow2"/>
      <target dev="vda" bus="virtio"/>
      <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
    </disk>
    <disk type="file" device="cdrom">
      <driver name="qemu" type="raw"/>
      <target dev="sdb" bus="sata"/>
      <readonly/>
      <address type="drive" controller="0" bus="0" target="0" unit="1"/>
    </disk>
    <controller type="usb" index="0" model="qemu-xhci" ports="15">
      <address type="pci" domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
    </controller>
    <controller type="pci" index="0" model="pcie-root"/>
    <controller type="pci" index="1" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="1" port="0x10"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="2" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="2" port="0x11"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
    </controller>
    <controller type="pci" index="3" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="3" port="0x12"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
    </controller>
    <controller type="pci" index="4" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="4" port="0x13"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x3"/>
    </controller>
    <controller type="pci" index="5" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="5" port="0x14"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x4"/>
    </controller>
    <controller type="pci" index="6" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="6" port="0x15"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x5"/>
    </controller>
    <controller type="pci" index="7" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="7" port="0x16"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x6"/>
    </controller>
    <controller type="pci" index="8" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="8" port="0x17"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x7"/>
    </controller>
    <controller type="pci" index="9" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="9" port="0x18"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="10" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="10" port="0x19"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x1"/>
    </controller>
    <controller type="pci" index="11" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="11" port="0x1a"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x2"/>
    </controller>
    <controller type="pci" index="12" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="12" port="0x1b"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x3"/>
    </controller>
    <controller type="pci" index="13" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="13" port="0x1c"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x4"/>
    </controller>
    <controller type="pci" index="14" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="14" port="0x1d"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x5"/>
    </controller>
    <controller type="sata" index="0">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
    </controller>
    <controller type="virtio-serial" index="0">
      <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
    </controller>
    <interface type="network">
      <mac address="52:54:00:81:ff:44"/>
      <source network="default"/>
      <model type="virtio"/>
      <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
    </interface>
    <serial type="pty">
      <target type="isa-serial" port="0">
        <model name="isa-serial"/>
      </target>
    </serial>
    <console type="pty">
      <target type="serial" port="0"/>
    </console>
    <channel type="spicevmc">
      <target type="virtio" name="com.redhat.spice.0"/>
      <address type="virtio-serial" controller="0" bus="0" port="1"/>
    </channel>
    <channel type='unix'>
      <source mode='bind'/>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='2'/>
    </channel>
    <input type="tablet" bus="usb">
      <address type="usb" bus="0" port="1"/>
    </input>
    <input type="mouse" bus="ps2"/>
    <input type="keyboard" bus="ps2"/>
    <tpm model="tpm-crb">
      <backend type="emulator" version="2.0"/>
    </tpm>
    <graphics type="spice" autoport="yes">
      <listen type="address"/>
      <image compression="off"/>
    </graphics>
    <sound model="ich9">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1b" function="0x0"/>
    </sound>
    <audio id="1" type="spice"/>
    <video>
      <model type="qxl" ram="65536" vram="65536" vgamem="16384" heads="1" primary="yes"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
    </video>
    <hostdev mode="subsystem" type="usb" managed="yes">
      <source>
        <vendor id="0x0bda"/>
        <product id="0x554e"/>
      </source>
      <address type="usb" bus="0" port="4"/>
    </hostdev>
    <redirdev bus="usb" type="spicevmc">
      <address type="usb" bus="0" port="2"/>
    </redirdev>
    <watchdog model="itco" action="reset"/>
    <memballoon model="virtio">
      <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
    </memballoon>
  </devices>
</domain>
```

## Install Windows
Install Windows as you would on any other machine.

<p align="center">
    <img src="./libvirt_images/16.png" width="700px"/>
</p>

Once you get to the point of selecting the location for installation, you will see there are no disks available. This is because the `VirtIO driver` needs to be specified manually.
1. Select `Load driver`.

<p align="center">
    <img src="./libvirt_images/17.png" width="700px"/>
</p>

2. The installer will then ask you to specify where the driver is located. Select the drive the `VirtIO` driver `.ISO` is mounted on.

<p align="center">
    <img src="./libvirt_images/18.png" width="700px"/>
</p>

3. Choose the appropriate driver for the operating system you've selected, which is likely either the `w10` or `w11` drivers.

<p align="center">
    <img src="./libvirt_images/19.png" width="700px"/>
</p>

4. The virtual hard disk should now be visible and available for selection.

<p align="center">
    <img src="./libvirt_images/20.png" width="700px"/>
</p>

The next hurdle will be bypassing the network selection screen. As the `VirtIO` drivers for networking have not yet been loaded, the virtual machine will not be able to be connected to the internet.
- For Windows 11: When prompted to select your country or region, press "Shift + F10" to open the command prompt. Enter `OOBE\BYPASSNRO` or `start ms-cxh:localonly` and press Enter. The system will restart, allowing you to select "I don't have internet" later on. It is crucial to run this command as soon as possible, as doing so later in the installation process will not work, and you may be required to create a Microsoft account despite not having an internet connection.

<p align="center">
    <img src="./libvirt_images/21.png" width="700px"/>
</p>

- For Windows 10: Simply click "I don't have internet".

<p align="center">
    <img src="./libvirt_images/22.png" width="700px"/>
</p>

Following the above, choose to "Continue with limited setup".

<p align="center">
    <img src="./libvirt_images/23.png" width="700px"/>
</p>

</details>

</details>

<details>
<summary>Final Configuration Steps</summary>

> [!Note]
> For those who followed libvirt:
> Open `File Explorer` and navigate to the drive where the `VirtIO` driver `.ISO` is mounted. Run `virtio-win-gt-x64.exe` to launch the `VirtIO` driver installer.

> [!Note]
> For those who followed Docker or Podman:
> Download [VirtIO drivers](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso) for the Windows virtual machine.
> Press right click and seelct mount .iso file.
> Open `File Explorer` and navigate to the drive where the `VirtIO` driver `.ISO` is mounted. Run `virtio-win-gt-x64.exe` to launch the `VirtIO` driver installer.


> VirtIO drivers enhance system performance and minimize overhead by enabling the Windows virtual machine to use specialised network and disk device drivers. These drivers are aware that they are operating inside a virtual machine, and cooperate with the hypervisor. This approach eliminates the need for the hypervisor to emulate physical hardware devices, which is a computationally expensive process. This setup allows guests to achieve high-performance network and disk operations, leveraging the benefits of paravirtualisation.
> The above link contains the latest release of the `VirtIO` drivers for Windows, compiled and signed by Red Hat. Older versions of the `VirtIO` drivers can be downloaded [here](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/?C=M;O=D).
> You can read more about `VirtIO` [here](https://wiki.libvirt.org/Virtio.html) and [here](https://developer.ibm.com/articles/l-virtio/).

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

## (Optional) Configuring a Fallback Shared Folder
When connecting to Windows through FreeRDP, your home folder will be shared automatically. However, this sharing setup does not apply when using Windows via virt-manager. To configure a fallback shared folder, follow these steps:

1. Navigate to "Virtual Hardware Details", then "Memory" and then check the box for "Enable shared memory".

2. Add filesystem hardware by going to "Virtual Hardware Details" and selecting "Add Hardware" followed by "Filesystem". Choose `virtiofs` as the driver, enter the path to the shared folder, and provide a name for the shared folder in the target path (e.g., "Windows Shared Folder").

3. Install [`WinFSP`](https://github.com/winfsp/winfsp/releases/) on Windows.

4. Enable and start a 'VirtIO Filesystem' service within Windows by running the following commands within a PowerShell prompt.
    ```PowerShell
    sc.exe create VirtioFsSvc binpath= "C:\Program Files\Virtio-Win\VioFS\virtiofs.exe" start=auto depend="WinFsp.Launcher/VirtioFsDrv" DisplayName="Virtio Filesystem Service"
    sc.exe start VirtioFsSvc
    ```

5. Reboot Windows.

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

> [!NOTE]
> You may also wish to install [Spice Guest Tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe) inside the virtual machine, which enables features like auto-desktop resize and cut-and-paste when accessing the virtual machine through `virt-manager`. Since WinApps uses RDP, however, this is unnecessary if you don't plan to access the virtual machine via `virt-manager`.

> [!IMPORTANT]
> If you installed VM via `virt-manager` look at Step 3 and Ensure `WAFLAVOR` is set to `"libvirt"` in your `~/.config/winapps/winapps.conf` to prevent WinApps looking for a `Docker` installation instead.

Finally, restart the virtual machine, but **DO NOT** log in. Close the virtual machine viewer and proceed to run the WinApps installation.

```bash
bash <(curl https://raw.githubusercontent.com/winapps-org/winapps/main/setup.sh)
```

You can search Windows VM for Advanced System Properties and change Performance Settings. And configure pagefile.

</details>

<details>
<summary>Step 2: Install Dependencies</summary>

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
<summary>Step 3: Create a WinApps Configuration File</summary>

> [!IMPORTANT]
> Make sure to change RDP_USER, RDP_PASS, RDP_IP to your previously configured values.

Create a configuration file at `~/.config/winapps/winapps.conf` containing the following:
```bash
##################################
#   WINAPPS CONFIGURATION FILE   #
##################################

# INSTRUCTIONS
# - Leading and trailing whitespace are ignored.
# - Empty lines are ignored.
# - Lines starting with '#' are ignored.
# - All characters following a '#' are ignored.

# [WINDOWS USERNAME]
RDP_USER="MyWindowsUser"

# [WINDOWS PASSWORD]
# NOTES:
# - If using FreeRDP v3.9.0 or greater, you *have* to set a password
RDP_PASS="MyWindowsPassword"

# [WINDOWS DOMAIN]
# DEFAULT VALUE: '' (BLANK)
RDP_DOMAIN=""

# [WINDOWS IPV4 ADDRESS]
# NOTES:
# - If using 'libvirt', 'RDP_IP' will be determined by WinApps at runtime if left unspecified.
# DEFAULT VALUE:
# - 'docker': '127.0.0.1'
# - 'podman': '127.0.0.1'
# - 'libvirt': '' (BLANK)
RDP_IP="127.0.0.1"

# [VM NAME]
# NOTES:
# - Only applicable when using 'libvirt'
# - The libvirt VM name must match so that WinApps can determine VM IP, start the VM, etc.
# DEFAULT VALUE: 'RDPWindows'
VM_NAME="RDPWindows"

# [WINAPPS BACKEND]
# DEFAULT VALUE: 'docker'
# VALID VALUES:
# - 'docker'
# - 'podman'
# - 'libvirt'
# - 'manual'
WAFLAVOR="docker"

# [DISPLAY SCALING FACTOR]
# NOTES:
# - If an unsupported value is specified, a warning will be displayed.
# - If an unsupported value is specified, WinApps will use the closest supported value.
# DEFAULT VALUE: '100'
# VALID VALUES:
# - '100'
# - '140'
# - '180'
RDP_SCALE="100"

# [MOUNTING REMOVABLE PATHS FOR FILES]
# NOTES:
# - By default, `udisks` (which you most likely have installed) uses /run/media for mounting removable devices.
#   This improves compatibility with most desktop environments (DEs).
# ATTENTION: The Filesystem Hierarchy Standard (FHS) recommends /media instead. Verify your system's configuration.
# - To manually mount devices, you may optionally use /mnt.
# REFERRENCE: https://wiki.archlinux.org/title/Udisks#Mount_to_/media
REMOVABLE_MEDIA="/run/media"

# [ADDITIONAL FREERDP FLAGS & ARGUMENTS]
# NOTES:
# - You can try adding /network:lan to these flags in order to increase performance, however, some users have faced issues with this.
# DEFAULT VALUE: '/cert:tofu /sound /microphone'
# VALID VALUES: See https://github.com/awakecoding/FreeRDP-Manuals/blob/master/User/FreeRDP-User-Manual.markdown
RDP_FLAGS="/grab-keyboard /cert:tofu /sound /microphone"

# [MULTIPLE MONITORS]
# NOTES:
# - If enabled, a FreeRDP bug *might* produce a black screen.
# DEFAULT VALUE: 'false'
# VALID VALUES:
# - 'true'
# - 'false'
MULTIMON="false"

# [DEBUG WINAPPS]
# NOTES:
# - Creates and appends to ~/.local/share/winapps/winapps.log when running WinApps.
# DEFAULT VALUE: 'true'
# VALID VALUES:
# - 'true'
# - 'false'
DEBUG="true"

# [AUTOMATICALLY PAUSE WINDOWS]
# NOTES:
# - This is currently INCOMPATIBLE with 'docker' and 'manual'.
# - See https://github.com/dockur/windows/issues/674
# DEFAULT VALUE: 'off'
# VALID VALUES:
# - 'on'
# - 'off'
AUTOPAUSE="off"

# [AUTOMATICALLY PAUSE WINDOWS TIMEOUT]
# NOTES:
# - This setting determines the duration of inactivity to tolerate before Windows is automatically paused.
# - This setting is ignored if 'AUTOPAUSE' is set to 'off'.
# - The value must be specified in seconds (to the nearest 10 seconds e.g., '30', '40', '50', etc.).
# - For RemoteApp RDP sessions, there is a mandatory 20-second delay, so the minimum value that can be specified here is '20'.
# - Source: https://techcommunity.microsoft.com/t5/security-compliance-and-identity/terminal-services-remoteapp-8482-session-termination-logic/ba-p/246566
# DEFAULT VALUE: '300'
# VALID VALUES: >=20
AUTOPAUSE_TIME="300"

# [FREERDP COMMAND]
# NOTES:
# - WinApps will attempt to automatically detect the correct command to use for your system.
# DEFAULT VALUE: '' (BLANK)
# VALID VALUES: The command required to run FreeRDPv3 on your system (e.g., 'xfreerdp', 'xfreerdp3', etc.).
FREERDP_COMMAND=""

# [TIMEOUTS]
# NOTES:
# - These settings control various timeout durations within the WinApps setup.
# - Increasing the timeouts is only necessary if the corresponding errors occur.
# - Ensure you have followed all the Troubleshooting Tips in the error message first.

# PORT CHECK
# - The maximum time (in seconds) to wait when checking if the RDP port on Windows is open.
# - Corresponding error: "NETWORK CONFIGURATION ERROR" (exit status 13).
# DEFAULT VALUE: '5'
PORT_TIMEOUT="5"

# RDP CONNECTION TEST
# - The maximum time (in seconds) to wait when testing the initial RDP connection to Windows.
# - Corresponding error: "REMOTE DESKTOP PROTOCOL FAILURE" (exit status 14).
# DEFAULT VALUE: '30'
RDP_TIMEOUT="30"

# APPLICATION SCAN
# - The maximum time (in seconds) to wait for the script that scans for installed applications on Windows to complete.
# - Corresponding error: "APPLICATION QUERY FAILURE" (exit status 15).
# DEFAULT VALUE: '60'
APP_SCAN_TIMEOUT="60"

```

> [!IMPORTANT]
> `RDP_USER` and `RDP_PASS` must correspond to a complete Windows user account and password, such as those created during Windows setup or for a domain user. User/PIN combinations are not valid for RDP access.

> [!IMPORTANT]
> To switch keyboard layout you need to add new keyboard layout in Windows, and then you can switch it by using Shift+Alt

> [!IMPORTANT]
> If you wish to use an alternative WinApps backend (other than `Docker`), uncomment and change `WAFLAVOR="docker"` to `WAFLAVOR="podman"` or `WAFLAVOR="libvirt"`.

### Configuration Options Explained
- If using a pre-existing Windows RDP server on your LAN, you must use `RDP_IP` to specify the location of the Windows server. You may also wish to configure a static IP address for this server.
- If running a Windows VM using `libvirt` with NAT enabled, leave `RDP_IP` commented out and WinApps will auto-detect the local IP address for the VM.
- For domain users, you can uncomment and change `RDP_DOMAIN`.
- On high-resolution (UHD) displays, you can set `RDP_SCALE` to the scale you would like to use (100, 140 or 180).
- To add additional flags to the FreeRDP call (e.g. `/prevent-session-lock 120`), uncomment and use the `RDP_FLAGS` configuration option.
- For multi-monitor setups, you can try enabling `MULTIMON`. A FreeRDP bug may result in a black screen however, in which case you should revert this change.
- If you enable `DEBUG`, a log will be created on each application start in `~/.local/share/winapps/winapps.log`.
- If using a system on which the FreeRDP command is not `xfreerdp` or `xfreerdp3`, the correct command can be specified using `FREERDP_COMMAND`.
</details>

<details>
<summary>Step 4: Test FreeRDP</summary>

1. Test establishing an RDP session by running the following command, replacing the `/u:`, `/p:`, and `/v:` values with the correct values specified in `~/.config/winapps/winapps.conf`.

    ```bash
    xfreerdp3 /u:"Your Windows Username" /p:"Your Windows Password" /v:192.168.122.2 /cert:tofu

    # Or, if you installed FreeRDP using Flatpak
    flatpak run --command=xfreerdp com.freerdp.FreeRDP /u:"Your Windows Username" /p:"Your Windows Password" /v:192.168.122.2 /cert:tofu
    ```

    - Please note that the correct `FreeRDP` command may vary depending on your system (e.g. `xfreerdp`, `xfreerdp3`, etc.).
    - Ensure you use the correct IP address for your Windows instance in the above command.
    - If prompted within the terminal window, choose to accept the certificate permanently.

    If the Windows desktop appears in a `FreeRDP` window, the configuration was successful and the correct RDP TLS certificate was enrolled on the Linux host. Disconnect from the RDP session and skip the following debugging step.

2. [DEBUGGING STEP] If an outdated or expired certificate is detected, the `FreeRDP` command will display output resembling the following. In this case, the old certificate will need to be removed and a new RDP TLS certificate installed.

    ```
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @           WARNING: CERTIFICATE NAME MISMATCH!           @
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    The hostname used for this connection (192.168.122.2:3389)
    does not match the name given in the certificate:
    Common Name (CN):
            RDPWindows
    A valid certificate for the wrong name should NOT be trusted!

    The host key for 192.168.122.2:3389 has changed

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
    Someone could be eavesdropping on you right now (man-in-the-middle attack)!
    It is also possible that a host key has just been changed.
    The fingerprint for the host key sent by the remote host is 8e:b4:d2:8e:4e:14:e7:4e:82:9b:07:5b:e1:68:40:18:bc:db:5f:bc:29:0d:91:83:f9:17:f9:13:e6:51:dc:36
    Please contact your system administrator.
    Add correct host key in /home/rohanbarar/.config/freerdp/server/192.168.122.2_3389.pem to get rid of this message.
    ```

    If you experience the above error, delete any old or outdated RDP TLS certificates associated with Windows, as they can prevent `FreeRDP` from establishing a connection.

    These certificates are located within `~/.config/freerdp/server/` and follow the naming format `<Windows-VM-IPv4-Address>_<RDP-Port>.pem` (e.g., `192.168.122.2_3389.pem`, `127.0.0.1_3389.pem`, etc.).

    If you use FreeRDP for purposes other than WinApps, ensure you only remove certificates related to the relevant Windows VM. If no relevant certificates are found, no action is needed.

    Following deletion, re-attempt establishing an RDP session.
</details>

<details>
<summary>Step 5: Run the WinApps Installer</summary>

With Windows still powered on, run the WinApps installer.

```bash
bash <(curl https://raw.githubusercontent.com/winapps-org/winapps/main/setup.sh)
```

Once WinApps is installed, a list of additional arguments can be accessed by running `winapps-setup --help`.

<img src="./winapps_installer_images/installer.gif" width=1898 alt="WinApps Installer Animation.">
</details>



<details>
<summary>Nix & NixOs Specific Install</summary>
# Installation using Nix

First, follow Step 1 of the normal installation guide to create your VM.
Then, install WinApps according to the following instructions.

After installation, it will be available under `winapps`, with the installer being available under `winapps-setup`
and the optional launcher being available under `winapps-launcher.`

## Using standalone Nix

First, make sure Flakes and the `nix` command are enabled.
In your `~/.config/nix/nix.conf`:
```
experimental-features = nix-command flakes
# specify to use binary cache (optional)
extra-substituters = https://winapps.cachix.org/
extra-trusted-public-keys = winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g=
extra-trusted-users = <your-username> # replace with your username
```

```bash
nix profile install github:winapps-org/winapps#winapps
nix profile install github:winapps-org/winapps#winapps-launcher # optional
```

## On NixOS using Flakes

```nix
# flake.nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      winapps,
      ...
    }:
    {
      nixosConfigurations.hostname = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs system;
        };

        modules = [
          ./configuration.nix
          (
            {
              pkgs,
              system ? pkgs.system,
              ...
            }:
            {
              # set up binary cache (optional)
              nix.settings = {
                substituters = [ "https://winapps.cachix.org/" ];
                trusted-public-keys = [ "winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g=" ];
              };

              environment.systemPackages = [
                winapps.packages."${system}".winapps
                winapps.packages."${system}".winapps-launcher # optional
              ];
            }
          )
        ];
      };
    };
}
```

## On NixOS without Flakes

[Flakes aren't real and they can't hurt you.](https://jade.fyi/blog/flakes-arent-real/).
However, if you still don't want to use flakes, you can use WinApps with flake-compat like:

```nix
# configuration.nix
{
  pkgs,
  system ? pkgs.system,
  ...
}:
{
  # set up binary cache (optional)
  nix.settings = {
    substituters = [ "https://winapps.cachix.org/" ];
    trusted-public-keys = [ "winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g=" ];
    trusted-users = [ "<your username>" ]; # replace with your username
  };

  environment.systemPackages =
    let
      winapps =
        (import (builtins.fetchTarball "https://github.com/winapps-org/winapps/archive/main.tar.gz"))
        .packages."${system}";
    in
    [
      winapps.winapps
      winapps.winapps-launcher # optional
    ];
}
```
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
