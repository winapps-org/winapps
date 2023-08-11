# winapps-mac
The winapps main project <br />
Originally created by fmstrat https://github.com/Fmstrat/winapps/

## Installation

### Step 1: Set up a Windows Virtual Machine
The best solution for running a VM as a subsystem for WinApps would be KVM. KVM is a CPU and memory-efficient virtualization engine. To set up the VM for WinApps, follow this guide:

- [Creating a Virtual Machine in KVM using UTM](docs/UTM.md)

If you already have a Virtual Machine or server you wish to use with WinApps, you will need to merge `install/RDPApps.reg` into the VM's Windows Registry. If this VM is in KVM and you want to use auto-IP detection, you will need to name the machine `RDPWindows`. Directions for both of these can be found in the guide linked above.

### Step 2: Download the repo and prerequisites
To get things going, use:
``` bash
brew install --cask xquartz # reboot after installing this
brew install coreutils freerdp
git clone -b legacy-macos https://github.com/winapps-org/winapps.git
cd winapps
```


### Step 3: Creating your WinApps configuration file
You will need to create a `~/.config/winapps/winapps.conf` configuration file with the following information in it:
``` bash
RDP_USER="MyWindowsUser"
RDP_PASS="MyWindowsPassword"
#RDP_DOMAIN="MYDOMAIN"
RDP_IP="127.0.0.1"
#RDP_SCALE=100
#RDP_FLAGS=""
#MULTIMON="true"
#DEBUG="true"
```
The username and password should be a full user account and password, such as the one created when setting up Windows or a domain user. It cannot be a user/PIN combination as those are not valid for RDP access.

Options:
- When using a pre-existing non-KVM RDP server, you can use the `RDP_IP` to specify it's location
- For domain users, you can uncomment and change `RDP_DOMAIN`
- On high-resolution (UHD) displays, you can set `RDP_SCALE` to the scale you would like [100|140|160|180]
- To add flags to the FreeRDP call, such as `/audio-mode:1` to pass in a mic, use the `RDP_FLAGS` configuration option
- For multi-monitor setups, you can try enabling `MULTIMON`, however if you get a black screen (FreeRDP bug) you will need to revert back
- If you enable `DEBUG`, a log will be created on each application start in `~/.local/share/winapps/winapps.log`

### Step 4: Run the WinApps installer
Lastly, check that FreeRDP can connect with:
```
bin/winapps check
```
You will see output from FreeRDP, as well as potentially have to accept the initial certificate. After that, a Windows Explorer window should pop up. You can close this window and press `Ctrl-C` to cancel out of FreeRDP.

If this step fails, try restarting the VM, or your problem could be related to:
- You need to accept the security cert the first time you connect (with 'check')
- Not enabling RDP in the Windows VM
- Not being able to connect to the IP of the VM
- Incorrect user credentials in `~/.config/winapps/winapps.conf`
- Not merging `install/RDPApps.reg` into the VM

## Running applications manually
WinApps offers a manual mode for running applications that are not configured. This is completed with the `manual` flag. Executables that are in the path do not require full path definition.
``` bash
./bin/winapps manual "C:\my\directory\executableNotInPath.exe"
./bin/winapps manual executableInPath.exe
```

Currently, this is the only mode supported on macOS 
