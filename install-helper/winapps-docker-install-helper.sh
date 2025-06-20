#!/bin/bash
set -e

USER_NAME=$(whoami)

function install_docker_arch() {
  sudo pacman -Sy --needed docker
  sudo systemctl enable --now docker.service
}

function install_docker_ubuntu() {
  sudo apt-get update
  sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  sudo systemctl enable --now docker
}

function install_docker() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      arch|manjaro)
        echo "Detected Arch-based distro: $NAME. Installing Docker via pacman..."
        install_docker_arch
        ;;
      ubuntu|debian)
        echo "Detected Debian-based distro: $NAME. Installing Docker via apt..."
        install_docker_ubuntu
        ;;
      *)
        echo "Unsupported OS: $NAME. Please install Docker manually." >&2
        exit 1
        ;;
    esac
  else
    echo "Cannot detect OS. Please install Docker manually." >&2
    exit 1
  fi
}

function install_docker_compose() {
  if ! docker compose version &>/dev/null; then
    echo "Docker Compose plugin not found, installing manually..."
    if command -v pacman &>/dev/null; then
      sudo pacman -Sy docker-compose
    else
      sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
    fi
  fi
}

function setup_docker_permissions() {
  sudo setfacl --modify user:${USER_NAME}:rw /var/run/docker.sock || {
    echo "Failed to set permissions on /var/run/docker.sock" >&2
    exit 1
  }
  echo "Docker socket permissions set for user ${USER_NAME}."
}

function load_iptables_modules() {
  echo -e "ip_tables\niptable_nat" | sudo tee /etc/modules-load.d/iptables.conf
  echo "iptables modules configured to load on boot."
}

function clone_and_edit_winapps() {
  if [ ! -d winapps ]; then
    echo "Cloning winapps repository..."
    git clone https://github.com/winapps-org/winapps.git || {
      echo "Failed to clone winapps repository." >&2
      exit 1
    }
  fi

  cd winapps

  # Defaults
  default_name="winapps"
  default_version="11"
  default_ram="4G"
  default_cpu="4"
  default_disk="64G"
  default_username="winapps"
  default_password="winapps"
  default_home="$HOME"
  default_port1="8006:8006"
  default_port2="3389:3389/tcp"
  default_port3="3389:3389/udp"

  form_result=$(yad --form --title="Edit winapps compose.yaml" \
    --field="Project Name":TXT "$default_name" \
    --field="Windows Version":TXT "$default_version" \
    --field="RAM Size":TXT "$default_ram" \
    --field="CPU Cores":TXT "$default_cpu" \
    --field="Disk Size":TXT "$default_disk" \
    --field="Windows Username":TXT "$default_username" \
    --field="Windows Password":TXT "$default_password" \
    --field="Linux HOME Path":TXT "$default_home" \
    --field="Port 1 (VNC)":TXT "$default_port1" \
    --field="Port 2 (RDP TCP)":TXT "$default_port2" \
    --field="Port 3 (RDP UDP)":TXT "$default_port3")

  if [ $? -ne 0 ]; then
    echo "Edit cancelled. Exiting."
    exit 0
  fi

  IFS="|" read -r name version ram cpu disk username password home port1 port2 port3 <<< "$form_result"

  cat > compose.yaml <<EOF
name: "$name" # Docker Compose Project Name.
volumes:
  data:
services:
  windows:
    image: ghcr.io/dockur/windows:latest
    container_name: WinApps
    environment:
      VERSION: "$version"
      RAM_SIZE: "$ram"
      CPU_CORES: "$cpu"
      DISK_SIZE: "$disk"
      USERNAME: "$username"
      PASSWORD: "$password"
      HOME: "$home"
    ports:
      - $port1
      - $port2
      - $port3
    cap_add:
      - NET_ADMIN
    stop_grace_period: 120s
    restart: on-failure
    volumes:
      - data:/storage
      - ${home}:/shared
      - ./oem:/oem
    devices:
      - /dev/kvm
      - /dev/net/tun
EOF

  echo "compose.yaml updated successfully."
}

function start_winapps_container() {
  cd "$HOME/winapps" || {
    echo "Cannot find winapps directory." >&2
    exit 1
  }
  docker compose --file ./compose.yaml up -d
  echo "WinApps container started."
}

function create_winapps_conf() {
  local conf_dir="$HOME/.config/winapps"
  mkdir -p "$conf_dir"

  cat > "$conf_dir/winapps.conf" <<EOF
##################################
#   WINAPPS CONFIGURATION FILE   #
##################################

# INSTRUCTIONS
# - Leading and trailing whitespace are ignored.
# - Empty lines are ignored.
# - Lines starting with '#' are ignored.
# - All characters following a '#' are ignored.

# [WINDOWS USERNAME]
RDP_USER="$username"

# [WINDOWS PASSWORD]
# NOTES:
# - If using FreeRDP v3.9.0 or greater, you *have* to set a password
RDP_PASS="$password"

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
# - By default, \`udisks\` (which you most likely have installed) uses /run/media for mounting removable devices.
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
EOF

  echo "Created ~/.config/winapps/winapps.conf with your Windows credentials."
}


# Run all steps
install_docker
install_docker_compose
setup_docker_permissions
load_iptables_modules
clone_and_edit_winapps
create_winapps_conf
start_winapps_container

echo "Install-helper finished successfully."
echo "Open your browser and go to: http://127.0.0.1:8006"
