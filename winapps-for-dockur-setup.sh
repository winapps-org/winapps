#!/bin/bash
#########################################################################################
# WinApps for Dockur/Windows v1.0
# David Harrop
# July 2024
#
# Automated Docker environment builder for WinApps (https://github.com/winapps-org/winapps)
# on Docker/Windows from https://github.com/dockur/windows
#
# This script offers two automatic Docker deployment options with WinApps:
#
# Option 1. Use Dockur's default network [Easy]
#  - Build is fully automated Docker/Windows build in a single script from just a few simple prompts
#  - Windows container shares an IP with the host
#     - Optionally restrict incoming RDP & VNC access to 127.0.0.1
#
# 2. Option 2: Use a macvlan [Advanced]
#   - Macvlans allow a container to act as a full LAN client with a separate DHCP IP & MAC address.
#      - Script walks the user through required CIDR input & will automatically build the virtual routing schema
#   - Pros:
#     - Allows 3-way sharing between the container, local host, and LAN
#     - Provides direct communication between the container and NIC, (no NAT or port forwarding)
#     - DHCP makes IP management consistent, aiding firewall rules and policies
#     - Some applications may require unique IP/MAC addresses for licensing
#     - Optionally restrict incoming RDP & VNC access to 127.0.0.1
#     - Automates creation of a complex build into a repeatable task
#   - Cons:
#     - As only macvlans are supported: (Dockur does not currently support L2 IPvlan bridging):
#        - As macvlans use multiple MAC addresses per interface
#            - This option is available only for ethernet-connected systems
#            - Macvlans are incompatible with WiFi topology (which requires a single MAC for session & encryption management)
#
# Script instructions
# 1. Run the script & answer the script prompts to customize your build
#    (Script "container defaults" can be edited just below)
# 2. Follow the build via http://127.0.0.1:8006 or http://x.x.x.x:8006
# 3. Restart Windows when it has finished installing
# 4. Refresh local Linux group permissions before working with Docker by either:
#    running newgrp docker | logging in to a new shell | rebooting Linux
# 5. Install your preferred Windows applications as needed
# 6. Run the ~/winapps/installer.sh to install WinApps
#
# Docker cheat sheet:
# Start/stop/enable/disable the container
#    docker compose -f file.yaml up -d # start container
#    docker stop <container-name>      # stop  container
#    docker update --restart=no <container-name> # diasble container auto start at boot
#    docker update --restart=on-failure <container-name> # enable container auto start at boot
#    sudo systemctl start|stop|disable macvlan-br.service # toggle macvlan routing config
#########################################################################################

# Container defaults
DEF_VERSION="win10" # see https://github.com/dockur/windows for all options
DEF_INSTALL_ISO="/home/user/your-install-image-here.iso"
DEF_HOSTNAME="RDP_Windows"
DEF_USERNAME="user"
DEF_PASSWORD=""
DEF_RAM_SIZE="4G"
DEF_CPU_CORES="4"
DEF_DISK_SIZE="64G"
DEF_CONTAINER_NAME="winapps"

# Script defaults (expert use onlny)
HOMEDIR=$(eval echo ~"${SUDO_USER}")
GITREPO="https://github.com/winapps-org/winapps.git"
PGK_FREERDP="freerdp3-x11"
FLAT_FREERDP="com.freerdp.FreeRDP"
VLAN_DEV="macvlan-br"
MAC_VLAN="winapps_macvlan"

# Text colours
CYAN='\033[1;36m'
GREY='\033[0;37m'
LGREEN='\033[0;92m'
LRED='\033[0;91m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear

echo
printf "${LGREEN}### WinApps for Dockur/Windows v1.0 #####################################################${GREY}
 ${CYAN}1.${GREY} Answer the script prompts to customize your build
 ${CYAN}2.${GREY} Follow the Windows install via ${CYAN}http://127.0.0.1:8006 or http://x.x.x.x:8006${GREY}
 ${CYAN}3.${GREY} Restart Windows when it has finished installing
 ${CYAN}4.${GREY} Refresh local Linux group permissions before working with Docker by either:
    ${CYAN}a.${GREY} running ${CYAN}newgrp docker${GREY} | ${CYAN}b.${GREY} logging in with a new shell | ${CYAN}c.${GREY} rebooting Linux
 ${CYAN}5.${GREY} Install your preferred Windows applications as needed
 ${CYAN}6.${GREY} Run ${CYAN}~/winapps/installer.sh${GREY} to install WinApps${NC}\n"

# First lets make sure the user is NOT running the script as root
if [[ $EUID -eq 0 ]]; then
    echo
    echo -e "${LRED}This script must NOT be run as root, it will prompt for sudo when needed." 1>&2
    echo -e "${NC}"
    exit 1
fi

# Prompt for a custom OS install source
echo
while true; do
    echo " Select an option for the OS install ISO:"
    echo "    1) Use default ISO: ${DEF_INSTALL_ISO}"
    echo "    2) Provide a new ISO path"
    echo "    3) No ISO (script will download Windows)"
    read -p "    Enter your choice (1, 2, or 3): " iso_choice

    case $iso_choice in
    1)
        INSTALL_ISO="${DEF_INSTALL_ISO}"
        break
        ;;
    2)
        read -p "    Enter the path to the custom OS install ISO: " custom_iso
        INSTALL_ISO="${custom_iso}"
        break
        ;;
    3)
        INSTALL_ISO=""
        break
        ;;
    *)
        echo " Invalid choice. Please enter 1, 2, or 3."
        ;;
    esac
done

# If no custom OS install ISO is provided, prompt for a Windows version to download
echo
if [ -z "${INSTALL_ISO}" ]; then
    echo -e "    ${CYAN}For Windows download options see https://github.com/dockur/windows${NC}"
    read -p "    Enter a Windows version to download (default: ${DEF_VERSION}): " version
    VERSION=${version:-$DEF_VERSION}
    VERSION_MSG="VERSION: $VERSION"
else
    VERSION="${DEF_VERSION}"
    VERSION_MSG="VERSION: ${VERSION} (ignored if ISO is provided)"
fi

# Prompt for Windows hostname
read -p "    Enter a Windows hostname (default: ${DEF_HOSTNAME}): " windows_hostname
WINDOWS_HOSTNAME=${windows_hostname:-$DEF_HOSTNAME}

# Prompt for username
read -p "    Enter Windows username (default: ${DEF_USERNAME}): " username
USERNAME=${username:-$DEF_USERNAME}

# Secure prompt for password with confirmation
while true; do
    read -s -p "    Enter Windows user password: " password
    echo
    read -s -p "    Confirm the password: " password_confirm
    echo
    if [ "${password}" == "${password_confirm}" ]; then
        PASSWORD=${password:-$DEF_PASSWORD}
        break
    else
        echo "    Passwords do not match. Please try again."
    fi
done

# Prompt for RAM size
read -p "    Enter VM RAM size (default: $DEF_RAM_SIZE): " ram_size
RAM_SIZE=${ram_size:-$DEF_RAM_SIZE}

# Prompt for CPU cores
read -p "    Enter VM CPU cores (default: $DEF_CPU_CORES): " cpu_cores
CPU_CORES=${cpu_cores:-$DEF_CPU_CORES}

# Prompt for disk size
read -p "    Enter VM disk size (default: $DEF_DISK_SIZE): " disk_size
DISK_SIZE=${disk_size:-$DEF_DISK_SIZE}

# Prompt for container name
read -p "    Enter container name (default: $DEF_CONTAINER_NAME): " container_name
CONTAINER_NAME=${container_name:-$DEF_CONTAINER_NAME}

# Display the chosen settings
echo
echo -e " ${CYAN}Your new container configuration:${NC}"
echo " INSTALL_ISO: ${INSTALL_ISO:-None}"
echo " $VERSION_MSG"
echo " WINDOWS_HOSTNAME: ${WINDOWS_HOSTNAME}"
echo " USERNAME: ${USERNAME}"
echo " RAM_SIZE: ${RAM_SIZE}"
echo " CPU_CORES: ${CPU_CORES}"
echo " DISK_SIZE: ${DISK_SIZE}"
echo " CONTAINER_NAME: ${CONTAINER_NAME}"

# Pause and wait for user input before continuing
echo -e "${CYAN}"
read -p " You will next be prompted for your sudo password... [Enter to continue or ctrl+x to exit]"
echo -e "${NC}"

clear

echo
printf "${LGREEN}### WinApps for Dockur/Windows v1.0 #####################################################${GREY}
 ${CYAN}1.${GREY} Answer the script prompts to customize your build
 ${CYAN}2.${GREY} Follow the Windows install via ${CYAN}http://127.0.0.1:8006 or http://x.x.x.x:8006${GREY}
 ${CYAN}3.${GREY} Restart Windows when it has finished installing
 ${CYAN}4.${GREY} Refresh local Linux group permissions before working with Docker by either:
    ${CYAN}a.${GREY} running ${CYAN}newgrp docker${GREY} | ${CYAN}b.${GREY} logging in with a new shell | ${CYAN}c.${GREY} rebooting Linux
 ${CYAN}5.${GREY} Install your preferred Windows applications as needed
 ${CYAN}6.${GREY} Run ${CYAN}~/winapps/installer.sh${GREY} to install WinApps${NC}\n"

# Now trigger the sudo prompt, this way we can apply sudo only as needed for certain commands
echo
sudo apt-get update -qq
echo
echo -e "${CYAN} ### Docker network & accessibilty options ###${NC}"

# Get network device & address info for Docker networking setup
read -r gateway interface <<<"$(ip route | awk '/default/ {print $3, $5}')"
ip_info=$(ip -o -f inet addr show "$interface" | awk '{print $4}')
ip_address=$(echo "$ip_info" | cut -d/ -f1)
cidr_prefix=$(echo "$ip_info" | cut -d/ -f2)
IFS=. read -r i1 i2 i3 i4 <<<"$(for i in $(seq 1 4); do printf "%d." "$((cidr_prefix >= (i * 8) ? 255 : (255 << (8 - (cidr_prefix % 8)) & 255)))"; done | sed 's/.$//')"

IFS=. read -r a b c d <<<"$ip_address"
IFS=. read -r m1 m2 m3 m4 <<<"$i1.$i2.$i3.$i4"
network_address=$(printf "%d.%d.%d.%d\n" "$((a & m1))" "$((b & m2))" "$((c & m3))" "$((d & m4))")

NIC=$(ip route | grep default | awk '{print $5}')
SUBNET=$network_address/$cidr_prefix
GATEWAY=$(ip route | grep default | awk '{print $3}')
CIDR="" # initialised for config menu

# Network selection menus
echo " Select container network configuration:"
echo "    1. Default network [Easy]   (Shared IP with host, no LAN browsing from Windows)"
echo -e "    2. DHCP LAN client [Advanced] (Separate IP, LAN access from Windows, ${YELLOW}ethernet only${NC})"
echo "    3. Exit"

# Function to validate CIDR format
validate_cidr() {
    local cidr=$1
    if [[ $cidr =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+$ ]]; then
        IFS='/' read -r subnet mask <<<"$cidr"
        IFS='.' read -r i1 i2 i3 i4 <<<"$subnet"
        if [[ $i1 -ge 0 && $i1 -le 255 && $i2 -ge 0 && $i2 -le 255 && $i3 -ge 0 && $i3 -le 255 && $i4 -ge 0 && $i4 -le 255 && $mask -ge 0 && $mask -le 32 ]]; then
            return 0
        fi
    fi
    return 1
}

while true; do
    read -p "    Enter your choice [1-3]: " choice

    case $choice in
    1)
        NET_CONFIG_OPTION="default"
        break
        ;;
    2)
        NET_CONFIG_OPTION="macvlan"
        echo
        echo -e "    ${YELLOW}Warning: For ethernet only as WiFi cannot support multiple MAC addresses required by macvlans${NC}"
        echo
        echo "    A minimum /30 range of free static IP addresses from your $SUBNET subnet is required (2 usable addresses)."
        echo "    This static subnet can be larger than /30, but must not overlap with your local DHCP scope."

        while true; do
            read -p "    Enter an available static IP subnet eg. 192.168.1.252/30 : " CIDR

            if validate_cidr "$CIDR"; then
                echo "    CIDR format is valid."

                # Get the lowest and highest usable IP addresses based on the CIDR provided
                IFS='/' read -r subnet mask <<<"$CIDR"
                num_addresses=$((2 ** (32 - mask)))
                IFS='.' read -r i1 i2 i3 i4 <<<"$subnet"
                subnet_decimal=$(((i1 << 24) + (i2 << 16) + (i3 << 8) + i4))
                broadcast_decimal=$((subnet_decimal + num_addresses - 1))
                first_usable_decimal=$((subnet_decimal + 1))
                last_usable_decimal=$((broadcast_decimal - 1))

                convert_decimal_to_ip() {
                    local ip_decimal=$1
                    printf "%d.%d.%d.%d" $(((ip_decimal >> 24) & 0xFF)) $(((ip_decimal >> 16) & 0xFF)) $(((ip_decimal >> 8) & 0xFF)) $((ip_decimal & 0xFF))
                }

                subnet_prefix=$(convert_decimal_to_ip "$subnet_decimal")
                lowest_ip=$(convert_decimal_to_ip "$first_usable_decimal") # Reserved for container's DATA volume IP address & http VNC access
                highest_ip=$(convert_decimal_to_ip "$last_usable_decimal") # Reserved for macvlan routing
                subnet_mask=$mask

                # Manually override macvlan addressing scheme here:
                container_ip=$lowest_ip
                vlan_ip=$highest_ip
                break
            else
                echo "Invalid CIDR format. Please enter a valid CIDR (e.g., 192.168.1.252/30)."
            fi
        done
        break
        ;;
    3)
        echo " Exiting..."
        exit 0
        ;;
    *)
        echo " Invalid option, please try again."
        ;;
    esac
done

echo
echo " Select container INBOUND network access:"
echo "    1. Allow only localhost"
echo "    2. Remotely accessible over LAN"
echo "    3. Exit"

while true; do
    read -p "    Enter your choice [1-3]: " choice

    case $choice in
    1)
        NET_ACCESS_OPTION="127.0.0.1:"
        break
        ;;
    2)
        NET_ACCESS_OPTION=""
        break
        ;;
    3)
        echo " Exiting..."
        exit 0
        ;;
    *)
        echo " Invalid option, please try again."
        ;;
    esac
done

echo
echo -e "${CYAN} ### WinApps dependenices ###${NC}"

# Check if specific FreeRDP packages are installed
PACKAGE_INSTALLED=$(dpkg -l | grep $PGK_FREERDP | awk '{print $2}')
if ! command -v flatpak &>/dev/null; then
    FLATPAK_INSTALLED=""
else
    FLATPAK_INSTALLED=$(flatpak list --app | grep $FLAT_FREERDP | awk '{print $3}')
fi

if [ -n "$PACKAGE_INSTALLED" ] || [ -n "$FLATPAK_INSTALLED" ]; then
    echo " These FreeRDP packages are already installed: $PACKAGE_INSTALLED$FLATPAK_INSTALLED"
else
    # If no FreeRDP packages are installed, choose one
    while true; do
        echo " FreeRDP installation source:"
        echo "    1) Install via Distro Repository"
        echo "    2) Install via Flatpak"
        echo "    3) Exit"

        read -p "    Enter your choice [1-3]: " choice

        case $choice in
        1)
            # Install via Distro Repository
            echo
            echo "    Installing FreeRDP via distro repository along with all other dependencies..."
            FREERDP_PACKAGES=$(apt-cache search $PGK_FREERDP)
            if [ -n "$FREERDP_PACKAGES" ]; then
                echo
                sudo apt-get install -y -qq $PGK_FREERDP
            else
                echo
                echo " No FreeRDP packages were found in the distro repository."
                echo
                exit 0
            fi
            break
            ;;
        2)
            # Install via Flatpak
            echo
            echo " Installing FreeRDP via Flatpak along with all other dependencies...."
            echo
            sudo apt install -y -qq flatpak
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
            flatpak install -y flathub com.freerdp.FreeRDP
            sudo flatpak override --filesystem=home com.freerdp.FreeRDP # To use `+home-drive`
            break
            ;;
        3)
            # Exit
            echo
            echo " Exiting the script."1
            echo
            exit 0
            ;;
        *)
            echo " Invalid choice. Please select a valid option."
            echo
            ;;
        esac
    done
fi

sudo apt-get -y -qq install dialog git

echo
echo -e "${CYAN} ### Adding Docker source repo & installing Docker engine ###${NC}"

# Dependencies for adding the Docker repo
sudo apt-get -y -qq install gnome-terminal ca-certificates curl

# Add Docker's official GPG key:
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "bookworm") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update

# Install Docker
sudo apt-get -y -qq install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"

# Create macvlan routing config for simultaneous LAN and host access, and make this all persistent after reboot
if [[ ${NET_CONFIG_OPTION} == "macvlan" ]]; then

    # Systemd method is the most compatible & simplest to comprehend / manually update
    sudo bash -c "cat <<EOF > /etc/systemd/system/${VLAN_DEV}.service
[Unit]
Description=macvlan bridge setup
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ip link add ${VLAN_DEV} link ${NIC} type macvlan mode bridge
ExecStart=/sbin/ip addr add ${vlan_ip}/32 dev ${VLAN_DEV}
ExecStart=/sbin/ip link set ${VLAN_DEV} up
ExecStart=/sbin/ip route add ${subnet_prefix}/${subnet_mask} dev ${VLAN_DEV}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF"

    sudo systemctl daemon-reload
    sudo systemctl enable "${VLAN_DEV}".service
    sudo systemctl start "${VLAN_DEV}".service
fi

# Clone WinApps
echo
echo -e "${CYAN} ### Cloning WinApps-org repository from GitHub ###${NC}"

cd "$HOMEDIR" || exit
git clone "$GITREPO"

# Add install.bat or RDPApps.reg customizations below

# Update WinApps unattended OEM setup script to set the Windows hostname during install
sed -i "/echo off/a wmic computersystem where caption='%COMPUTERNAME%' rename $HOSTNAME\ntimeout /t 3 /nobreak" winapps/oem/install.bat

# A simple hack to obtain the new container's DHCP address and populate the RDP test script with the correct address
if [[ ${NET_CONFIG_OPTION} == "macvlan" ]]; then
    LINE=$(printf "ipconfig > \\\\\\\\${container_ip}\\Data\\CONTAINER_IP.txt")
    echo "$LINE" >>winapps/oem/install.bat
fi

# Create a simple script for testing RDP connections to the new container
rm -f "$HOMEDIR"/winapps/test-rdp.sh # remove any old version first
cat <<EOF >"$HOMEDIR"/winapps/test-rdp.sh
#!/bin/bash
# WinApps pre-insallation RDP test script

# Initial Docker parameters used by install script
  USERNAME="${USERNAME}"
  PASSWORD="${PASSWORD}"
  NET_CONFIG_OPTION="${NET_CONFIG_OPTION}"

# Determine the RDP connection address based on the initial network installation
if [ "\${NET_CONFIG_OPTION}" == "default" ]; then
   CONTAINER_IP="127.0.0.1"
   else
   CONTAINER_IP=\$(awk -F': ' '/IPv4 Address/ {print $2}' ~/CONTAINER_IP.txt)
fi

# Optionally override the RDP test connection IP:
# CONTAINER_IP=your.rdp.ip.here.

xfreerdp3 /cert:ignore /d: /u:"\${USERNAME}" /p:"\${PASSWORD}" /scale:100 /v:"\${CONTAINER_IP}" /sound /microphone +clipboard
EOF
chmod +x "$HOMEDIR"/winapps/test-rdp.sh

echo
echo -e "${CYAN} ### Creating the WinApps configuration file ###${NC}"

rm -f "${HOMEDIR}"/.config/winapps/winapps.conf # remove any old version first
mkdir -p "${HOMEDIR}"/.config/winapps
cat <<EOF >"${HOMEDIR}"/.config/winapps/winapps.conf
RDP_USER="$USERNAME"
RDP_PASS="$PASSWORD"
#RDP_DOMAIN="MYDOMAIN"
#RDP_IP="192.168.123.111"
#WAFLAVOR="docker" # Acceptable values are 'docker', 'podman' and 'libvirt'.
#RDP_SCALE=180 # Acceptable values are 100, 140, and 180.
#RDP_FLAGS="/sound /microphone +clipboard"
#MULTIMON="true"
#DEBUG="true"
#FREERDP_COMMAND="xfreerdp"
EOF
echo " Done"

echo
echo -e "${CYAN} ### Creating the Docker compose file ###${NC}"

# Always build the default yaml file as a fallback from macvlan version
rm -f "$HOMEDIR"/winapps/default-net.yaml # remove any old version first
cat <<EOF >"$HOMEDIR"/winapps/default-net.yaml
name: "winapps"
volumes:
  data:
services:
  windows:
    image: dockurr/windows
    container_name: $CONTAINER_NAME
    environment:
      VERSION: "$VERSION"
      RAM_SIZE: "$RAM_SIZE"
      CPU_CORES: "$CPU_CORES"
      DISK_SIZE: "$DISK_SIZE"
      USERNAME: "$USERNAME"
      PASSWORD: "$PASSWORD"
      HOME: "${HOME}"
    privileged: true
    cap_add:
      - NET_ADMIN
    ports:
      - ${NET_ACCESS_OPTION}8006:8006
      - ${NET_ACCESS_OPTION}3389:3389/tcp
      - ${NET_ACCESS_OPTION}3389:3389/udp
    stop_grace_period: 120s
    restart: on-failure
    volumes:
      - data:/storage
      - ${HOME}:/shared
      - ./oem:/oem
      - $INSTALL_ISO:/custom.iso
    devices:
      - /dev/kvm # Enable KVM.
EOF

# Build this file only if macvlan option is selected
if [[ ${NET_CONFIG_OPTION} == "macvlan" ]]; then
    rm -f "$HOMEDIR"/winapps/macvlan-net.yaml # remove any old version first
    cat <<EOF >"$HOMEDIR"/winapps/macvlan-net.yaml
name: "winapps"
volumes:
  data:
services:
  windows:
    image: dockurr/windows
    container_name: $CONTAINER_NAME
    environment:
      DHCP: "Y"
      VERSION: "$VERSION"
      RAM_SIZE: "$RAM_SIZE"
      CPU_CORES: "$CPU_CORES"
      DISK_SIZE: "$DISK_SIZE"
      USERNAME: "$USERNAME"
      PASSWORD: "$PASSWORD"
      HOME: "${HOME}"
    privileged: true
    cap_add:
      - NET_ADMIN
    ports:
      - ${NET_ACCESS_OPTION}8006:8006
      - ${NET_ACCESS_OPTION}3389:3389/tcp
      - ${NET_ACCESS_OPTION}3389:3389/udp
    stop_grace_period: 120s
    restart: on-failure
    volumes:
      - data:/storage
      - ${HOME}:/shared
      - ./oem:/oem
      - $INSTALL_ISO:/custom.iso
    devices:
      - /dev/kvm # Enable KVM.
      - /dev/vhost-net
    device_cgroup_rules:
      - 'c *:* rwm'
    networks:
      vlan:
        ipv4_address: $container_ip
networks:
  vlan:
    external: true
    name: ${MAC_VLAN}
EOF

fi

echo " Done"

echo
echo -e "${CYAN} ### Starting automated Docker Windows container build ###${NC}"

# To perform everything in one script we need to start a new shell to refresh group membership (avoids using sudo)
LOCAL_IP=$(ip -4 addr show "$(ip route show default | awk '/default/ { print $5 }')" | awk '/inet / {print $2}' | cut -d/ -f1)

newgrp docker <<END

# Start a new container based on the chosen networking option
if [[ ${NET_CONFIG_OPTION} == "default" ]]; then

    # Build with the default networking
    echo
    echo -e " ${YELLOW}WINDOWS CONTAINER BUILD IS NOW UNDERWAY...${NC}"
    echo -e " You can observe the build at http://127.0.0.1:8006 or http://$LOCAL_IP:8006"
    echo -e " Please wait for the Windows build to finish before testing RDP with:"
    echo -e " ${CYAN}$HOMEDIR/winapps/test-rdp.sh${NC}"
    echo
    docker compose -f "$HOMEDIR"/winapps/default-net.yaml up
else
    docker network create -d macvlan \
  --subnet="${SUBNET}" \
  --gateway="${GATEWAY}" \
  --ip-range="${CIDR}" \
  --aux-address "host=${vlan_ip}" \
  -o parent="${NIC}" \
  "${MAC_VLAN}"

    # Build with macvlan networking
    echo
    echo -e " ${YELLOW}WINDOWS CONTAINER BUILD IS NOW UNDERWAY...${NC}"
    echo -e " You can observe the build at http://$container_ip:8006"
    echo -e " Please wait for the Windows build to finish before testing RDP with:"
    echo -e " ${CYAN}$HOMEDIR/winapps/test-rdp.sh${NC}"
    echo
    docker compose -f "$HOMEDIR"/winapps/macvlan-net.yaml up
fi

END
