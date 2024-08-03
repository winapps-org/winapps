#!/bin/bash
###########################################################################################################
# WinApps for Dockur/Windows v1.0
# David Harrop
# August 2024
#
# Automated Docker environment builder for Windows containers on Linux with WinApps
# See these great repos for more:
#  - Dockur/Windows https://github.com/dockur/windows
#  - WinApps-org  https://github.com/winapps-org/winapps
#
# This script offers two automatic Docker deployment options with WinApps:
#
# Option 1. Uses Dockur's default network [Easy]
#  - A fully automated Docker/Windows build with in a single script from just a few simple prompts
#  - Windows container shares an IP with the host
#     - (Optionally) restricts incoming RDP and VNC access to 127.0.0.1
#
# 2. Option 2: Uses macvlan networking [Advanced]
#   - Macvlans allow a container to act as a full LAN client with a separate DHCP IP and MAC address
#      - This script walks the user through required CIDR inputs and automatically builds the required routing schema
#   - Pros:
#     - Allows 3-way sharing between the container, local host, and LAN
#     - Provides direct communication between the container and NIC, which means no NAT or port forwarding is necessary
#     - Use of DHCP helps keep IP management consistent, aiding in firewall rule and network policy continuity
#     - Useful for applications that require a unique IP or MAC addresses for licensing
#     - (Optionally) restrict incoming RDP and VNC access to 127.0.0.1
#     - Turns a complex build into a repeatable task, with potential for creating a low cost virtual desktop infrastructure
#   - Cons:
#    - Because macvlans create multiple MAC addresses per interface:
#       - This option is available only for ETHERNET connected systems because Wi-Fi architecture
#         relies on a single and consistent MAC, macvlan links cannot be added to a Wi-Fi  NIC
#
# Script instructions
# 1. Run the script (without root permissions) & answer the script prompts to customize your build
#    (Script "container defaults" can be edited just below)
# 2. Follow the build via VNC http://127.0.0.1:8006 or http://x.x.x.x:8006
# 3. IMPORTANT: Restart Linux when the Windows installation is complete
# 4. Test rdp from Linux by running ~/test-rdp.sh
# 5. Install your preferred Windows applications as needed via RDP or VNC
# 6. Run ~/winapps/installer.sh to install WinApps
#
# Script OS support:                    Tested
# - Debian (Bullseye & Bookworm)..........ok
# - LMDE  (5 & 6).........................ok
# - Ubuntu (Focal, Jammy & Noble).........ok
# - Linux Mint (20 -> 22).................ok
#
# Docker cheat sheet:
# Start/stop/enable/disable the container
#    docker compose -f file.yaml up -d # start container
#    docker stop <container-name>      # stop  container
#    docker update --restart=no <container-name> # disable container auto start at boot
#    docker update --restart=on-failure <container-name> # enable container auto start at boot
#    sudo systemctl start|stop|disable macvlan-br.service # toggle macvlan routing config
############################################################################################################

# Container defaults
DEFAULT_VERSION="tiny11" # see https://github.com/dockur/windows for all options
DEFAULT_INSTALL_ISO="/home/david/w10_ent_iot_ltsc_2021_x64.iso"  # eg. /home/$USER/your-installer.iso
DEFAULT_HOSTNAME="RDP_Windows"
DEFAULT_USERNAME="user"
DEFAULT_PASSWORD=""
DEFAULT_RAM_SIZE="4G"
DEFAULT_CPU_CORES="4"
DEFAULT_DISK_SIZE="64G"
#DEFAULT_CONTAINER_NAME="WinApps" # Changing container name breaks WinApps, kept for other use cases
DEFAULT_ENABLE_SOUND="yes"

# Script defaults (expert use only)
HOMEDIR=$(eval echo ~"${SUDO_USER}")
GITREPO="https://github.com/winapps-org/winapps.git"
PGK_FREERDP="freerdp3-x11"
FLAT_FREERDP="com.freerdp.FreeRDP"
VLAN_DEV_NAME="macvlan-br"
MAC_VLAN_NAME="winapps_macvlan"
CONTAINER_IP="" # Override auto IP selection ( use with > /30 subnets)   
VLAN_IP=""      # Override auto IP selection ( use with > /30 subnets)  

# Text colours
BLUE='\033[38;5;33m'
GREEN='\033[38;5;34m'
LRED='\033[38;5;196m'
ORANGE='\033[38;5;208m'
WHITE='\033[38;5;15m'
NC='\033[0m'

clear
set -e

echo
printf "%b\n" "${GREEN}## WinApps for Dockur/Windows v1.0 ################################################"
printf "%b\n" "${BLUE} 1. ${NC}Answer script prompts to suit your build"
printf "%b\n" "${BLUE} 2. ${NC}Follow the Windows install via VNC ${BLUE}http://127.0.0.1:8006 or http://x.x.x.x:8006"
printf "%b\n" "${BLUE} 3. ${NC}IMPORTANT! Restart Linux when the Windows installation is complete"
printf "%b\n" "${BLUE} 4. ${NC}Install your preferred Windows applications via RDP or VNC"
printf "%b\n" "${BLUE} 5. ${NC}Run ${BLUE}~/winapps/installer.sh${NC} to install WinApps"

# Make sure the script is NOT being run as root
if [[ $EUID -eq 0 ]]; then
    echo
    echo -e "${LRED}This script must NOT be run as root, it will prompt for sudo when needed.${NC}" 1>&2
    echo
    exit 1
fi

# Translate distro codenames into a standard lexicon
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    echo
    echo -e " ${GREEN}${PRETTY_NAME^^} $(echo "detected, OK to proceed..." | tr '[:lower:]' '[:upper:]')${NC}"
else
    echo -e " ${LRED}Error: /etc/os-release file not found & distro not identified, exiting...${NC}"
    echo
    exit 1
fi

# Correlate distro codenames to their Debian codebase to match with Docker repo version names
# To include additional Docker distro support in future, adjust the below
# Debian 12 Bookworm (Jammy)     |  Debian 11 Bullseye (Focal) |   Debian 13 "Trixie"
#--------------------------------|-----------------------------|--- -------------------------
#| Ubuntu   | Mint      | LMDE6  | Ubuntu  | Mint    | LMDE5   | Ubuntu  | Mint    | LMDE    |
#|----------|-----------|--------|---------|---------|---------|---------|---------|---------|
#| Jammy    | Virginia  | Faye   | Focal   | Una     | Elsie   |         |         |         |
#| Noble    | Victoria  |        |         | Uma     |         |         |         |         |
#|          | Vera      |        |         | Ulyssa  |         |         |         |         |
#|          | Vanessa   |        |         | Ulyana  |         |         |         |         |
#|          | Wilma     |        |         |         |         |         |         |         |

case "${VERSION_CODENAME,,}" in
bookworm | jammy | noble | virginia | victoria | vera | vanessa | wilma | faye)
    VERSION_CODENAME="bookworm"
    ;;
bullseye | focal | una | uma | ulyssa | ulyana | elsie)
    VERSION_CODENAME="bullseye"
    ;;
*)
    # Set catch all default to latest Docker repo version
    VERSION_CODENAME="bookworm"
    ;;
esac

# Prompt for a custom OS install source
echo

# Check if the default ISO is set
if [ -z "${DEFAULT_INSTALL_ISO}" ]; then
    default_iso_message="No default set"
    default_option_set=false
else
    default_iso_message="${DEFAULT_INSTALL_ISO}"
    default_option_set=true
fi
echo -e "${BLUE} ## Windows container setup ##"
while true; do
    echo -e "    ${ORANGE}Windows install source:${NC}"
    echo -e "    1) Use default ISO ${WHITE}${default_iso_message}${NC}"
    echo "    2) Enter ISO path"
    echo "    3) Install Windows from download"
    read -r -p "    Enter your choice (1, 2, or 3): " iso_choice

    case $iso_choice in
    1)
      if [ "$default_option_set" = true ]; then
                if [ -e "$DEFAULT_INSTALL_ISO" ]; then
                    INSTALL_ISO="${DEFAULT_INSTALL_ISO}"
                    break
                else
                    echo "    Error: The default ISO file does not exist at ${DEFAULT_INSTALL_ISO}"
                    echo "    Please check the path and try again."
                    echo
                fi
            else
                echo "    No default ISO is set. Please enter 2 or 3."
                echo
            fi
            ;;
    2)
        read -r -p "    Enter the path to your Windows install ISO: " custom_iso
        if [ -e "$custom_iso" ]; then
                    INSTALL_ISO="${custom_iso}"
                    break
                else
                    echo "    Error: The ISO file does not exist at ${custom_iso}"
                    echo "    Please check the path and try again."
                    echo
                fi
        ;;
    3)
        INSTALL_ISO=""
        break
        ;;
    *)
        echo "    Invalid choice. Please enter 1, 2, or 3."
        echo
        ;;
    esac
done

# If no custom OS install ISO is provided, prompt for a Windows version to download
if [ -z "${INSTALL_ISO}" ]; then
    echo
    echo -e "    ${BLUE}For Windows download options see https://github.com/dockur/windows${NC}"
    read -r -p "    Enter a Windows version to download (default: ${DEFAULT_VERSION}): " version
    VERSION=${version:-$DEFAULT_VERSION}
    VERSION_MSG="download $VERSION"
else
    VERSION="${DEFAULT_VERSION}"
    VERSION_MSG="try ISO install first, else download ${VERSION}"
fi

# Prompt for Windows hostname
echo
echo -e "    ${ORANGE}Windows virtual machine configuration:${NC}"
read -r -p "    Enter Windows hostname (default: ${DEFAULT_HOSTNAME}): " windows_hostname
WINDOWS_HOSTNAME=${windows_hostname:-$DEFAULT_HOSTNAME}

# Prompt for username
read -r -p "    Enter Windows username (default: ${DEFAULT_USERNAME}): " username
USERNAME=${username:-$DEFAULT_USERNAME}

# Secure prompt for password with confirmation
while true; do
    read -r -s -p "    Enter Windows user password: " password
    echo
    read -r -s -p "    Confirm user password: " password_confirm
    echo
    if [ "${password}" == "${password_confirm}" ]; then
        PASSWORD=${password:-$DEFAULT_PASSWORD}
        break
    else
        echo "    Passwords do not match. Please try again."
        echo
    fi
done

# Prompt for RAM size
read -r -p "    Enter VM RAM size (default: $DEFAULT_RAM_SIZE): " ram_size
RAM_SIZE=${ram_size:-$DEFAULT_RAM_SIZE}

# Prompt for CPU cores
read -r -p "    Enter VM CPU cores (default: $DEFAULT_CPU_CORES): " cpu_cores
CPU_CORES=${cpu_cores:-$DEFAULT_CPU_CORES}

# Prompt for disk size
read -r -p "    Enter VM disk size (default: $DEFAULT_DISK_SIZE): " disk_size
DISK_SIZE=${disk_size:-$DEFAULT_DISK_SIZE}

# Prompt for container name - # Container name must remain as "WinApps", this function is kept for other use cases
#read -r -p "    Enter container name (default: $DEFAULT_CONTAINER_NAME): " container_name
#CONTAINER_NAME=${container_name:-$DEFAULT_CONTAINER_NAME}

# Prompt for sound config
enable_sound() {
    SOUND="on"
}

disable_sound() {
    SOUND="off"
}

while true; do
    read -r -p "    Enable sound? (yes/no) [default: ${DEFAULT_ENABLE_SOUND}]: " choice
    choice="${choice:-${DEFAULT_ENABLE_SOUND}}"

    case "$choice" in
    yes | YES | y | Y)
        enable_sound
        break
        ;;
    no | NO | n | N)
        disable_sound
        break
        ;;
    *)
        echo "    Invalid choice. Please enter 'yes' or 'no'."
        echo
        ;;
    esac
done

# Display the selected custom settings before continuing
echo
echo -e "    ${BLUE}Configuration summary:${NC}"
echo -e "    Install ISO.......${WHITE}${INSTALL_ISO:-skip}${NC}"
echo -e "    Windows version...${WHITE}${VERSION_MSG}${NC}"
echo -e "    Windows hostname..${WHITE}${WINDOWS_HOSTNAME}${NC}"
echo -e "    Username..........${WHITE}${USERNAME}${NC}"
echo -e "    RAM size..........${WHITE}${RAM_SIZE}${NC}"
echo -e "    CPU cores.........${WHITE}${CPU_CORES}${NC}"
echo -e "    Disk size.........${WHITE}${DISK_SIZE}${NC}"
#echo -e "    Container name...${WHITE}${CONTAINER_NAME}${NC}"
echo -e  "    Sound.............${WHITE}${SOUND}${NC}"

# Pause and wait for user input before continuing
echo
read -r -p "$(echo -e "${BLUE}    You will now be prompted for your sudo password... [Enter to continue or ctrl+z to exit]${NC}")"
echo

clear

echo
printf "%b\n" "${GREEN}## WinApps for Dockur/Windows v1.0 ################################################"
printf "%b\n" "${BLUE} 1. ${NC}Answer script prompts to suit your build"
printf "%b\n" "${BLUE} 2. ${NC}Follow the Windows install via VNC ${BLUE}http://127.0.0.1:8006 or http://x.x.x.x:8006"
printf "%b\n" "${BLUE} 3. ${NC}IMPORTANT! Restart Linux when the Windows installation is complete"
printf "%b\n" "${BLUE} 4. ${NC}Install your preferred Windows applications via RDP or VNC"
printf "%b\n" "${BLUE} 5. ${NC}Run ${BLUE}~/winapps/installer.sh${NC} to install WinApps"

# Now trigger the sudo prompt, this way we can apply sudo only as needed for certain commands
echo
sudo apt-get update -qq
echo
echo -e "${BLUE} ## Docker configuration options ##${NC}"

# Get network default NIC IP address and current subnet details for Docker macvlan networking setup
# shellcheck disable=SC2034
read -r gateway interface <<<"$(ip route | awk '/default/ {print $3, $5}')"
ip_info=$(ip -o -f inet addr show "$interface" | awk '{print $4}')
ip_address=$(echo "$ip_info" | cut -d/ -f1)
cidr_prefix=$(echo "$ip_info" | cut -d/ -f2)
IFS=. read -r i1 i2 i3 i4 <<<"$(for i in $(seq 1 4); do printf "%d." "$((cidr_prefix >= (i * 8) ? 255 : (255 << (8 - (cidr_prefix % 8)) & 255)))"; done | sed 's/.$//')"
IFS=. read -r a b c d <<<"$ip_address"
IFS=. read -r m1 m2 m3 m4 <<<"$i1.$i2.$i3.$i4"
network_address=$(printf "%d.%d.%d.%d\n" "$((a & m1))" "$((b & m2))" "$((c & m3))" "$((d & m4))")

NIC=$(ip route | grep default | awk '{print $5}')
IP_ADDRESS=$ip_address
SUBNET=$network_address/$cidr_prefix
GATEWAY=$(ip route | grep default | awk '{print $3}')
CIDR="" # initialised for config menu

# Network selection menus
echo -e "    ${ORANGE}Network configuration:${NC}"
echo "    1. Default network [Easy]     (Shared IP with host)"
echo -e "    2. Macvlan network [Advanced] (Separate DHCP IP & MAC address, full LAN client, ${ORANGE}ethernet only${NC})"
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
    read -r -p "    Enter your choice [1-3]: " choice

    case $choice in
    1)
        NET_CONFIG_OPTION="default"
        break
        ;;
    2)
        NET_CONFIG_OPTION="macvlan"
        echo
        echo -e "    ${ORANGE}Warning: For ethernet only as Wi-Fi cannot support multiple MAC addresses required by macvlans${NC}"
        echo
        echo "    A minimum /30 range of free static IP addresses from your $SUBNET subnet is required (2 usable addresses)."
        echo "    This static subnet can be larger than /30, but must not overlap with your local DHCP scope."

        while true; do
            read -r -p "    Enter an available static IP subnet eg. 192.168.1.252/30 : " CIDR

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

                # Choose between auto macvlan addressing or manually prescribed IP addresses:
				if [ -z "${CONTAINER_IP}" ]; then
				  container_ip=${lowest_ip}
				   else 
				  container_ip=${CONTAINER_IP}
				fi
				
				if [ -z "${VLAN_IP}" ]; then
				  vlan_ip=$highest_ip
				   else
				  vlan_ip=${VLAN_IP}
				fi 
				
                break
            else
                echo "Invalid CIDR format. Please enter a valid CIDR (e.g., 192.168.1.252/30)."
            fi
        done
        break
        ;;
    3)
        echo "    Exiting..."
        echo
        exit 0
        ;;
    *)
        echo " Invalid option, please try again."
        echo
        ;;
    esac
done

echo
echo -e "    ${ORANGE}Container INBOUND network access:${NC}"
echo "    1. Allow localhost only"
echo "    2. Remotely accessible over LAN"
echo "    3. Exit"

while true; do
    read -r -p "    Enter your choice [1-3]: " choice

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
        echo "    Exiting..."
        echo
        exit 0
        ;;
    *)
        echo " Invalid option, please try again."
        echo
        ;;
    esac
done

echo
echo -e "${BLUE} ## WinApps dependencies ##${NC}"

# Check if specific FreeRDP packages are installed
PACKAGE_INSTALLED=$(dpkg -l | grep $PGK_FREERDP | awk '{print $2}')
if ! command -v flatpak &>/dev/null; then
    FLATPAK_INSTALLED=""
else
    FLATPAK_INSTALLED=$(flatpak list --app | grep $FLAT_FREERDP | awk '{print $3}')
fi

if [ -n "$PACKAGE_INSTALLED" ] || [ -n "$FLATPAK_INSTALLED" ]; then
    echo "    FreeRDP packages already installed: $PACKAGE_INSTALLED$FLATPAK_INSTALLED"
else
    # If no FreeRDP packages are installed, choose one
    while true; do
        echo -e "    ${ORANGE}FreeRDP installation source:${NC}"
        echo "    1) Install via Distro Repository"
        echo "    2) Install via Flatpak"
        echo "    3) Exit"

        read -r -p "    Enter your choice [1-3]: " choice

        case $choice in
        1)
            # Install via Distro Repository
            echo
            echo "    Installing FreeRDP via distro repository along with all other dependencies..."
            FREERDP_PACKAGES=$(apt-cache search $PGK_FREERDP)
            if [ -n "$FREERDP_PACKAGES" ]; then
                echo
                sudo apt-get install -y -qq $PGK_FREERDP || exit 1
                RDP_CHOICE="distro"
            else
                echo
                echo -e "    ${ORANGE}No supported FreeRDP packages were found in the distro repository."
                echo -e "    Trying to install via Flatpak instead...${NC}"
                # Attempt to install via Flatpak
                update_flatpak() {
                    echo "    Updating Flatpak..."
                    sudo flatpak update -y || exit 1
                }

                install_flatpak() {
                    echo
                    echo "    Flatpak not found. Installing Flatpak..."
                    echo
                    sudo apt install -y flatpak || exit 1
                }

                # Check if Flatpak is installed
                if command -v flatpak &>/dev/null; then
                    update_flatpak
                else
                    install_flatpak
                    update_flatpak
                fi

                sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || exit 1
                sudo flatpak install -y flathub com.freerdp.FreeRDP || exit 1
                sudo flatpak override --filesystem=home com.freerdp.FreeRDP || exit 1
                RDP_CHOICE="flatpak"
            fi
            break
            ;;
        2)
            # Install via Flatpak
            echo
            echo "    Installing FreeRDP via Flatpak along with all other dependencies...."
            echo
            update_flatpak() {
                echo "    Updating Flatpak..."
                sudo flatpak update -y || exit 1
            }

            install_flatpak() {
                echo "    Flatpak not found. Installing Flatpak..."
                sudo apt install -y flatpak || exit 1
            }

            # Check if Flatpak is installed
            if command -v flatpak &>/dev/null; then
                update_flatpak
            else
                install_flatpak
                update_flatpak
            fi

            sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || exit 1
            sudo flatpak install -y flathub com.freerdp.FreeRDP || exit 1
            sudo flatpak override --filesystem=home com.freerdp.FreeRDP || exit 1
            break
            ;;
        3)
            # Exit
            echo
            echo " Exiting the script..."
            echo
            exit 0
            ;;
        *)
            echo "     Invalid choice. Please select a valid option."
            echo
            ;;
        esac
    done
fi

sudo apt-get -y -qq install dialog git

echo
echo -e "${BLUE} ## Adding Docker source repo & installing Docker engine ##${NC}"

# Dependencies for adding the Docker repo
sudo apt-get -y -qq install gnome-terminal ca-certificates curl

# Add Docker's official GPG key:
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $VERSION_CODENAME stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update

# Install Docker
echo "Selecting $VERSION_CODENAME Docker repository..."
sudo apt-get -y -qq install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
    echo -e " ${LRED}Docker installation failed, check if the distro VERSION_CODENAME is supported by Docker. Exiting...${NC}"
    echo
    exit 1
}
sudo usermod -aG docker "$USER"

# Create macvlan routing config for simultaneous LAN and host access, and make this all persistent after reboot
if [[ ${NET_CONFIG_OPTION} == "macvlan" ]]; then

    # Systemd method is used to create persistent routes as it is most compatible and easy to manually update
    sudo bash -c "cat <<EOF > /etc/systemd/system/${VLAN_DEV_NAME}.service
[Unit]
Description=macvlan bridge setup
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ip link add ${VLAN_DEV_NAME} link ${NIC} type macvlan mode bridge
ExecStart=/sbin/ip addr add ${vlan_ip}/32 dev ${VLAN_DEV_NAME}
ExecStart=/sbin/ip link set ${VLAN_DEV_NAME} up
ExecStart=/sbin/ip route add ${subnet_prefix}/${subnet_mask} dev ${VLAN_DEV_NAME}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF"

    sudo systemctl daemon-reload
    sudo systemctl enable "${VLAN_DEV_NAME}".service
    sudo systemctl start "${VLAN_DEV_NAME}".service
fi

# Clone WinApps
echo
echo -e "${BLUE} ## Cloning WinApps-org repository from GitHub ##${NC}"

rm -rf "$HOMEDIR/winapps"
cd "${HOMEDIR}" || exit 1
git clone "$GITREPO"

# install.bat and  RDPApps.reg customizations:
    # Update WinApps unattended OEM setup script to set the Windows hostname during install
    sed -i "/echo off/a wmic computersystem where caption='%COMPUTERNAME%' rename $HOSTNAME\ntimeout /t 3 /nobreak" winapps/oem/install.bat

    # Hack to obtain the new container's DHCP address and populate the RDP test script with the correct address
    if [[ ${NET_CONFIG_OPTION} == "macvlan" ]]; then
        LINE=$(printf "ipconfig > \\\\\\\\%s\\Data\\CONTAINER_DHCP_IP.txt" "${container_ip}")
        echo "$LINE" >>winapps/oem/install.bat
    fi

    # Workaround to enable or disable sound - this will be overwritten with any subsequent git update
    if [[ ${SOUND} == "on" ]]; then
        sed -i 's/audio-mode:1/audio-mode:0/g' "${HOMEDIR}"/winapps/bin/winapps
    elif [[ ${SOUND} == "off" ]]; then
        sed -i 's/audio-mode:0/audio-mode:1/g' "${HOMEDIR}"/winapps/bin/winapps
    fi

# Create a simple script for testing RDP connections to the new container
cat <<EOF >"${HOMEDIR}"/winapps/test-rdp.sh
#!/bin/bash
# WinApps pre-installation RDP test script

# Initial Docker parameters used by install script
  USERNAME="${USERNAME}"
  PASSWORD="${PASSWORD}"
  NET_CONFIG_OPTION="${NET_CONFIG_OPTION}"
  RDP_CHOICE="${RDP_CHOICE}"

# Determine the RDP connection IP address based on the network type chosen at installation
if [ "\${NET_CONFIG_OPTION}" == "default" ]; then
   CONTAINER_IP="127.0.0.1"
   elif [ "\${NET_CONFIG_OPTION}" == "macvlan" ]; then
   CONTAINER_IP=\$(awk -F': ' '/IPv4 Address/ {print $2}' ~/CONTAINER_DHCP_IP.txt)
fi

# Optionally override the RDP test connection IP:
# CONTAINER_IP=your.rdp.ip.here.

if [[ "\${RDP_CHOICE}" == "distro" ]]; then
xfreerdp3 /cert:ignore /d: /u:"\${USERNAME}" /p:"\${PASSWORD}" /scale:100 /v:"\${CONTAINER_IP}" /audio-mode:0 /dynamic-resolution +clipboard
elif [[ "\${RDP_CHOICE}" == "flatpak" ]]; then
flatpak run com.freerdp.FreeRDP /cert:ignore /d: /u:"\${USERNAME}" /p:"\${PASSWORD}" /scale:100 /v:"\${CONTAINER_IP}" /audio-mode:0 /dynamic-resolution +clipboard
fi
EOF
chmod +x "${HOMEDIR}"/winapps/test-rdp.sh

echo
echo -e "${BLUE} ## Creating the WinApps configuration file ##${NC}"

mkdir -p "${HOMEDIR}"/.config/winapps
cat <<EOF >"${HOMEDIR}"/.config/winapps/winapps.conf
RDP_USER="$USERNAME"
RDP_PASS="$PASSWORD"
#RDP_DOMAIN="MYDOMAIN"
#RDP_IP="192.168.123.111"
#WAFLAVOR="docker" # Acceptable values are 'docker', 'podman' and 'libvirt'.
#RDP_SCALE=180 # Acceptable values are 100, 140, and 180.
RDP_FLAGS="/audio-mode:0 /dynamic-resolution +clipboard" # audio-mode:0 = sound on
#MULTIMON="true"
#DEBUG="true"
#FREERDP_COMMAND="xfreerdp"
EOF
echo " Done"

echo
echo -e "${BLUE} ## Creating the Docker compose file ##${NC}"

# Always build the default yaml file as a fallback from macvlan version
cat <<EOF >"${HOMEDIR}"/.config/winapps/default-net.yaml
name: "WinApps"
volumes:
  data:
services:
  windows:
    image: dockurr/windows
    container_name: WinApps # Dont change $CONTAINER_NAME
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
    devices:
      - /dev/kvm # Enable KVM.
EOF

CUSTOM_ISO_LINE="      - ${INSTALL_ISO}:/custom.iso"
# Add the install ISO option to the default network yaml file only if this option is populated
if [ -n "${INSTALL_ISO}" ]; then
   sed -i '/services:/,/volumes:/{/volumes:/a\
'"$CUSTOM_ISO_LINE"'
}' "${HOMEDIR}/.config/winapps/default-net.yaml"
fi

# Build this file only if macvlan option is selected
if [[ ${NET_CONFIG_OPTION} == "macvlan" ]]; then
    cat <<EOF >"${HOMEDIR}"/.config/winapps/macvlan-net.yaml
name: "WinApps"
volumes:
  data:
services:
  windows:
    image: dockurr/windows
    container_name: WinApps # Don't change $CONTAINER_NAME
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
    name: ${MAC_VLAN_NAME}
EOF

# Add the install ISO option to the macvlan network yaml file only if this option is populated
if [ -n "${INSTALL_ISO}" ]; then
  sed -i '/services:/,/volumes:/{/volumes:/a\
'"${CUSTOM_ISO_LINE}"'
}' "${HOMEDIR}/.config/winapps/macvlan-net.yaml"
fi
fi

echo " Done"

echo
echo -e "${BLUE} ## Starting automated Docker Windows container build ##${NC}"

# To perform everything in one script we need to start a new shell to refresh group membership (avoids using sudo)
newgrp docker <<END

# To allow the script to be re-run, clear old macvlan and any incomplete installs
if [[ ${NET_CONFIG_OPTION} == "macvlan" ]] && docker network ls --filter name=^"${MAC_VLAN_NAME}"$ --format "{{.Name}}" | grep -w "${MAC_VLAN_NAME}" > /dev/null; then
    docker stop "${CONTAINER_NAME}" > /dev/null
    docker network rm -f "${MAC_VLAN_NAME}" > /dev/null
    docker system prune -f -a > /dev/null
fi

# Start a new container based on the chosen networking option
if [[ ${NET_CONFIG_OPTION} == "default" ]]; then

    # Build with the default networking
    echo
    echo -e " ${ORANGE}WINDOWS CONTAINER BUILD IS NOW UNDERWAY...${NC}"
    echo -e " ${GREEN}You can observe the build at http://127.0.0.1:8006 or http://$IP_ADDRESS:8006${NC}"
    echo " Please wait for Windows to finish installing before testing RDP with the below command:"
    echo -e " ${BLUE}$HOMEDIR/winapps/test-rdp.sh${NC}"
    echo
    docker compose -f "${HOMEDIR}"/.config/winapps/default-net.yaml up

elif [[ ${NET_CONFIG_OPTION} == "macvlan" ]]; then
    echo -e " Creating macvlan...${NC}"
    docker network create -d macvlan \
  --subnet="${SUBNET}" \
  --gateway="${GATEWAY}" \
  --ip-range="${CIDR}" \
  --aux-address "host=${vlan_ip}" \
  -o parent="${NIC}" \
  "${MAC_VLAN_NAME}"

    # Build with macvlan networking
    echo
    echo -e " ${ORANGE}WINDOWS CONTAINER BUILD IS NOW UNDERWAY...${NC}"
    echo -e " ${GREEN}You can observe the build at http://$container_ip:8006${NC}"
    echo " Please wait for Windows to finish installing before testing RDP with the below command:"
    echo -e " ${BLUE}$HOMEDIR/winapps/test-rdp.sh${NC}"
    echo
    docker compose -f "${HOMEDIR}"/.config/winapps/macvlan-net.yaml up
fi

END
