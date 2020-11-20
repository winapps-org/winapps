# Creating a Virtual Machine in KVM
This step-by-step guide will take you through setting up a CPU and memory efficient virtual machine to use with WinApps leveraging KVM, an open-source virtualization software contained in most linux distributions.

## Install KVM
First up, you must install KVM and the Virtual Machine Manager. By installing `virt-manager`, you will get everything you need for your distribution:
```bash
sudo apt-get install -y virt-manager
```

## Download the Windows Professional and KVM VirtIO drivers
You will need Windows 10 Professional (or Enterprise or Server) to run RDP apps, Windows 10 Home will not suffice. You will also need drivers for VirtIO to ensure the best performance and lowest overhead for your system. You can download these at the following links.

Windows 10 ISO: https://www.microsoft.com/en-us/software-download/windows10ISO

KVM VirtIO drivers (for all distros): https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

## Create your virtual machine
The following guide will take you through the setup. If you are an expert user, you may wish to:
- [Define a VM from XML (may not work on all systems)](#define-a-vm-from-xml)
- [Run KVM in user mode](#run-kvm-in-user-mode)

Otherwise, to set up the standard way, open `virt-manager` (Virtual Machines).

![](kvm/00.png)

Next, go to `Edit`->`Preferences`, and check `Enable XML editing`, then click the `Close` button.

![](kvm/01.png)

Now it is time to add a new VM by clicking the `+` button.

![](kvm/02.png)

Choose `Local install media` and click `Forward`.

![](kvm/03.png)

Now select the location of your Windows 10 ISO, and `Automatically detect` the installation.

![](kvm/04.png)

Set your memory and CPUs. We recommend `2` CPUs and `4096MB` for memory. We will be using a Memory Ballooning service, meaning 4096 is the maximum amount of memory the VM will ever use, but will not use this amount except when it is needed.

![](kvm/05.png)

Choose your virtual disk size, keep in mind this is the maximum size the disk will grow to, but it will not take up this space until it needs it.

![](kvm/06.png)

Next, name your machine `RDPWindows` so that WinApps can detect it, and choose to `Customize configuration before install`.

![](kvm/07.png)

After clicking `Finish`, ensure under CPU that `Copy host CPU configuration` is selected, and `Apply`.

**NOTE:** Sometimes this gets turned off after Windows is installed. You should check this option after install as well.

![](kvm/08.png)

Next, go to the `XML` tab, and edit the `<clock>` section to contain:
```xml
<clock offset='localtime'>
  <timer name='hpet' present='yes'/>
  <timer name='hypervclock' present='yes'/>
</clock>
```
Then `Apply`. This will drastically reduce idle CPU usage (from ~25% to ~3%).

![](kvm/09.png)

Next, under Memory, lower the `Current allocation` to the minimum memory the VM should use. We recommend `1024MB`.

![](kvm/10.png)

Under `Boot options`, check `Start virtual machine on host boot up`.

![](kvm/11.png)

For SATA Disk 1, set the `Disk bus` to `VirtIO`.

![](kvm/12.png)

For the NIC, set the `Device model` to `virtio`.

![](kvm/13.png)

Click the `Add Hardware` button in the lower right, and choose `Storage`. For `Device type`, select `CDROM device` and choose the VirtIO driver ISO you downloaded earlier. This will give the Windows 10 Installer access to drivers during the install process. Now click `Finish` to add the new CDROM device.

![](kvm/14.png)

You are now ready to click `Begin Installation`

![](kvm/15.png)

Now move on to installing the virtual machine.

## Install the virtual machine
From here out you will install Windows 10 Professional as you would on any other machine.

![](kvm/16.png)

Once you get to the point of selecting the location for installation, you will see there are no disks available. This is because we need to load the VirtIO driver. Select `Load driver`.

![](kvm/17.png)

The installer will then ask you to specify where the driver is located. Select the `E:\` drive or whichever drive the VirtIO driver ISO is located on.

![](kvm/18.png)

Choose the appropriate driver for the OS you have selected, which is most likely the `w10` driver for Windows 10.

![](kvm/19.png)

You will now see a disk you can select for the installation.

![](kvm/20.png)

Windows will begin to install, and you will likely need to reboot the VM a number times during this process.

![](kvm/21.png)

At some point, you will come to a network screen. This is because the VirtIO drivers for the network have not yet been loaded. Simply click `I don't have internet`.

![](kvm/22.png)

It will confirm your choice, so just choose `Continue with limited setup`.

![](kvm/23.png)

After you get into Windows and login with the user you created during the install. Open up `Explorer` and navigate the `E:\` drive or wherever the VirtIO driver ISO is mounted. Double click the `virt-win-gt-64.exe` file to launch the VirtIO driver installer.

![](kvm/24.png)

Leave everything as default and click `Next` through the installer. This will install device drivers as well as the Memory Ballooning service.

![](kvm/25.png)

Once you finish the driver install, you will need to make some registry changes to enable RDP Applications to run on the system. Start by downloading the `RDPApps.reg` file from the WinApps repo by visiting https://github.com/Fmstrat/winapps/blob/main/install/RDPApps.reg, right clicking on the `Raw` button, and clicking on `Save target as`.

![](kvm/26.png)

Once you have downloaded the registry file, right click on it, and choose `Merge`, then accept any confirmations along the way.

![](kvm/27.png)

Next up, we need to rename the VM so that WinApps can locate it. Go to the start menu and type `About` to bring up the `About your PC` settings.

![](kvm/28.png)

Scroll down and click on `Rename this PC`

![](kvm/29.png)

Rename to `RDPWindows`, and then `Next`, but **do not** restart.

![](kvm/30.png)

Lastly, scroll down to `Remote Desktop`, and toggle `Enable Remote Desktop` on, and `Confirm`.

![](kvm/31.png)

At this point you will need to restart and you have completed your setup.

Rather than restart you can go right ahead and install other applications like Microsoft Office or Adobe CC that could be used through WinApps.

You may also wish to install the [Spice Guest Tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe) inside the VM which enables features like auto-desktop resize and cut-and-paste when using `virt-manager`. As WinApps uses RDP, this is not necessary if you do not plan to access the machine via `virt-manager`.

Once you are finished, restart the VM, but do not log in. Simply close the VM viewer, and close the Virtual Machine Manager.

## Expert installs

### Define a VM from XML
This expert guide for XML imports is specific to Ubuntu 20.04 and may not work on all hardware platforms.

You can refer to the [KVM](https://www.linux-kvm.org) documentation for specifics, but the first thing you need to do is set up a Virtual Machine running Windows 10 Professional (or any version that supports RDP). First, install KVM:
``` bash
sudo apt-get install -y virt-manager
```
Now, copy your Windows ISO and VirtIO iso (links to download in the main guide) into the folder and update the `kvm/RDPWindows.xml` appropriately.

Next, define a VM called RDPWindows from the sample XML file with:
``` bash
virsh define kvm/RDPWindows.xml
virsh autostart RDPWindows
```
You should then open the VMs properties in `virt-manager` and ensure that under CPU `Copy host CPU configuration` is selected.

Boot it up, install windows, and then [Install the virtual machine](#install-the-virtual-machine).

### Run KVM in user mode
Now set up KVM to run as your user instead of root and allow it through AppArmor (for Ubuntu 20.04 and above):
``` bash
sudo sed -i "s/#user = "root"/user = "$(id -un)"/g" /etc/libvirt/qemu.conf
sudo sed -i "s/#group = "root"/group = "$(id -gn)"/g" /etc/libvirt/qemu.conf
sudo usermod -a -G kvm $(id -un)
sudo usermod -a -G libvirt $(id -un)
sudo systemctl restart libvirtd
sudo ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
```
You will likely need to reboot to ensure your current shell is added to the group.



