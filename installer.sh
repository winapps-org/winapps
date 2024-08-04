#!/usr/bin/env bash
# shellcheck disable=SC2034           # Silence warnings regarding unused variables globally.

### GLOBAL CONSTANTS ###
# ANSI ESCAPE SEQUENCES
readonly BOLD_TEXT="\033[1m"          # Bold
readonly CLEAR_TEXT="\033[0m"         # Clear
readonly COMMAND_TEXT="\033[0;37m"    # Grey
readonly DONE_TEXT="\033[0;32m"       # Green
readonly ERROR_TEXT="\033[1;31m"      # Bold + Red
readonly EXIT_TEXT="\033[1;41;37m"    # Bold + White + Red Background
readonly FAIL_TEXT="\033[0;91m"       # Bright Red
readonly INFO_TEXT="\033[0;33m"       # Orange/Yellow
readonly SUCCESS_TEXT="\033[1;42;37m" # Bold + White + Green Background
readonly WARNING_TEXT="\033[1;33m"    # Bold + Orange/Yellow

# ERROR CODES
readonly EC_FAILED_CD="1"        # Failed to change directory to location of script.
readonly EC_BAD_ARGUMENT="2"     # Unsupported argument passed to script.
readonly EC_EXISTING_INSTALL="3" # Existing conflicting WinApps installation.
readonly EC_NO_CONFIG="4"        # Absence of a valid WinApps configuration file.
readonly EC_MISSING_DEPS="5"     # Missing dependencies.
readonly EC_NO_SUDO="6"          # Insufficient privilages to invoke superuser access.
readonly EC_NOT_IN_GROUP="7"     # Current user not in group 'libvirt' and/or 'kvm'.
readonly EC_VM_OFF="8"           # Windows 'libvirt' VM powered off.
readonly EC_VM_PAUSED="9"        # Windows 'libvirt' VM paused.
readonly EC_VM_ABSENT="10"       # Windows 'libvirt' VM does not exist.
readonly EC_CONTAINER_OFF="11"   # Windows Docker container is not running.
readonly EC_NO_IP="12"           # Windows does not have an IP address.
readonly EC_BAD_PORT="13"        # Windows is unreachable via RDP_PORT.
readonly EC_RDP_FAIL="14"        # FreeRDP failed to establish a connection with Windows.
readonly EC_APPQUERY_FAIL="15"   # Failed to query Windows for installed applications.
readonly EC_INVALID_FLAVOR="16"  # Backend specified is not 'libvirt', 'docker' or 'podman'.

# PATHS
# 'BIN'
readonly SYS_BIN_PATH="/usr/local/bin"                  # UNIX path to 'bin' directory for a '--system' WinApps installation.
readonly USER_BIN_PATH="${HOME}/.local/bin"             # UNIX path to 'bin' directory for a '--user' WinApps installation.
readonly USER_BIN_PATH_WIN='\\tsclient\home\.local\bin' # WINDOWS path to 'bin' directory for a '--user' WinApps installation.
# 'APP'
readonly SYS_APP_PATH="/usr/share/applications"                        # UNIX path to 'applications' directory for a '--system' WinApps installation.
readonly USER_APP_PATH="${HOME}/.local/share/applications"             # UNIX path to 'applications' directory for a '--user' WinApps installation.
readonly USER_APP_PATH_WIN='\\tsclient\home\.local\share\applications' # WINDOWS path to 'applications' directory for a '--user' WinApps installation.
# 'APPDATA'
readonly SYS_APPDATA_PATH="/usr/local/share/winapps"                  # UNIX path to 'application data' directory for a '--system' WinApps installation.
readonly USER_APPDATA_PATH="${HOME}/.local/share/winapps"             # UNIX path to 'application data' directory for a '--user' WinApps installation.
readonly USER_APPDATA_PATH_WIN='\\tsclient\home\.local\share\winapps' # WINDOWS path to 'application data' directory for a '--user' WinApps installation.
# 'Installed Batch Script'
readonly BATCH_SCRIPT_PATH="${USER_APPDATA_PATH}/installed.bat"          # UNIX path to a batch script used to search Windows for applications.
readonly BATCH_SCRIPT_PATH_WIN="${USER_APPDATA_PATH_WIN}\\installed.bat" # WINDOWS path to a batch script used to search Windows for applications.
# 'Installed File'
readonly TMP_INST_FILE_PATH="${USER_APPDATA_PATH}/installed.tmp"          # UNIX path to a temporary file containing the names of detected officially supported applications.
readonly TMP_INST_FILE_PATH_WIN="${USER_APPDATA_PATH_WIN}\\installed.tmp" # WINDOWS path to a temporary file containing the names of detected officially supported applications.
readonly INST_FILE_PATH="${USER_APPDATA_PATH}/installed"                  # UNIX path to a file containing the names of detected officially supported applications.
readonly INST_FILE_PATH_WIN="${USER_APPDATA_PATH_WIN}\\installed"         # WINDOWS path to a file containing the names of detected officially supported applications.
# 'PowerShell Script'
readonly PS_SCRIPT_PATH="./install/ExtractPrograms.ps1"                          # UNIX path to a PowerShell script used to store the names, executable paths and icons (base64) of detected applications.
readonly PS_SCRIPT_HOME_PATH="${USER_APPDATA_PATH}/ExtractPrograms.ps1"          # UNIX path to a copy of the PowerShell script within the user's home directory to enable access by Windows.
readonly PS_SCRIPT_HOME_PATH_WIN="${USER_APPDATA_PATH_WIN}\\ExtractPrograms.ps1" # WINDOWS path to a copy of the PowerShell script within the user's home directory to enable access by Windows.
# 'Detected File'
readonly DETECTED_FILE_PATH="${USER_APPDATA_PATH}/detected"          # UNIX path to a file containing the output generated by the PowerShell script, formatted to define bash arrays.
readonly DETECTED_FILE_PATH_WIN="${USER_APPDATA_PATH_WIN}\\detected" # WINDOWS path to a file containing the output generated by the PowerShell script, formatted to define bash arrays.
# 'FreeRDP Connection Test File'
readonly TEST_PATH="${USER_APPDATA_PATH}/FreeRDP_Connection_Test"          # UNIX path to temporary file whose existence is used to confirm a successful RDP connection was established.
readonly TEST_PATH_WIN="${USER_APPDATA_PATH_WIN}\\FreeRDP_Connection_Test" # WINDOWS path to temporary file whose existence is used to confirm a successful RDP connection was established.
# 'WinApps Configuration File'
readonly CONFIG_PATH="${HOME}/.config/winapps/winapps.conf" # UNIX path to the WinApps configuration file.
# 'Inquirer Bash Script'
readonly INQUIRER_PATH="./install/inquirer.sh" # UNIX path to the 'inquirer' script, which is used to produce selection menus.

# REMOTE DESKTOP CONFIGURATION
readonly VM_NAME="RDPWindows"  # Name of the Windows VM (FOR 'libvirt' ONLY).
readonly RDP_PORT=3389         # Port used for RDP on Windows.
readonly DOCKER_IP="127.0.0.1" # Localhost.

### GLOBAL VARIABLES ###
# USER INPUT
OPT_SYSTEM=0    # Set to '1' if the user specifies '--system'.
OPT_USER=0      # Set to '1' if the user specifies '--user'.
OPT_UNINSTALL=0 # Set to '1' if the user specifies '--uninstall'.
OPT_AOSA=0      # Set to '1' if the user specifies '--setupAllOfficiallySupportedApps'.

# WINAPPS CONFIGURATION FILE
RDP_USER=""        # Imported variable.
RDP_PASS=""        # Imported variable.
RDP_DOMAIN=""      # Imported variable.
RDP_IP=""          # Imported variable.
WAFLAVOR="docker"  # Imported variable.
RDP_SCALE=100      # Imported variable.
RDP_FLAGS=""       # Imported variable.
MULTIMON="false"   # Imported variable.
DEBUG="true"       # Imported variable.
FREERDP_COMMAND="" # Imported variable.
MULTI_FLAG=""      # Set based on value of $MULTIMON.

# PERMISSIONS AND DIRECTORIES
SUDO=""         # Set to "sudo" if the user specifies '--system', or "" if the user specifies '--user'.
BIN_PATH=""     # Set to $SYS_BIN_PATH if the user specifies '--system', or $USER_BIN_PATH if the user specifies '--user'.
APP_PATH=""     # Set to $SYS_APP_PATH if the user specifies '--system', or $USER_APP_PATH if the user specifies '--user'.
APPDATA_PATH="" # Set to $SYS_APPDATA_PATH if the user specifies '--system', or $USER_APPDATA_PATH if the user specifies '--user'.

# INSTALLATION PROCESS
INSTALLED_EXES=() # List of executable file names of officially supported applications that have already been configured during the current installation process.

### TRAPS ###
set -o errtrace              # Ensure traps are inherited by all shell functions and subshells.
trap "waTerminateScript" ERR # Catch non-zero return values.

### FUNCTIONS ###
# Name: 'waTerminateScript'
# Role: Terminates the script when a non-zero return value is encountered.
# shellcheck disable=SC2317 # Silence warning regarding this function being unreachable.
function waTerminateScript() {
    # Store the non-zero exit status received by the trap.
    local EXIT_STATUS=$?

    # Display the exit status.
    echo -e "${EXIT_TEXT}Exiting with status '${EXIT_STATUS}'.${CLEAR_TEXT}"

    # Terminate the script.
    exit "$EXIT_STATUS"
}

# Name: 'waUsage'
# Role: Displays usage information for the script.
function waUsage() {
    echo -e "Usage:
  ${COMMAND_TEXT}./installer.sh --user${CLEAR_TEXT}                                        # Install WinApps and selected applications in ${HOME}
  ${COMMAND_TEXT}./installer.sh --system${CLEAR_TEXT}                                      # Install WinApps and selected applications in /usr
  ${COMMAND_TEXT}./installer.sh --user --setupAllOfficiallySupportedApps${CLEAR_TEXT}      # Install WinApps and all officially supported applications in ${HOME}
  ${COMMAND_TEXT}./installer.sh --system --setupAllOfficiallySupportedApps${CLEAR_TEXT}    # Install WinApps and all officially supported applications in /usr
  ${COMMAND_TEXT}./installer.sh --user --uninstall${CLEAR_TEXT}                            # Uninstall everything in ${HOME}
  ${COMMAND_TEXT}./installer.sh --system --uninstall${CLEAR_TEXT}                          # Uninstall everything in /usr
  ${COMMAND_TEXT}./installer.sh --help${CLEAR_TEXT}                                        # Display this usage message."
}

# Name: 'waSetWorkingDirectory'
# Role: Changes the working directory to the directory containing the script.
function waSetWorkingDirectory() {
    # Declare variables.
    local SCRIPT_DIR_PATH="" # Stores the absolute path of the directory containing the script.

    # Determine the absolute path to the directory containing the script.
    SCRIPT_DIR_PATH=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")

    # Silently change the working directory.
    if ! cd "$SCRIPT_DIR_PATH" &>/dev/null; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}DIRECTORY CHANGE FAILURE.${CLEAR_TEXT}"

        # Display error details.
        echo -e "${INFO_TEXT}Failed to change the working directory to ${CLEAR_TEXT}${COMMAND_TEXT}${SCRIPT_DIR_PATH}${CLEAR_TEXT}${INFO_TEXT}.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Ensure:"
        echo -e "  - ${COMMAND_TEXT}${SCRIPT_DIR_PATH}${CLEAR_TEXT} exists."
        echo -e "  - ${COMMAND_TEXT}${SCRIPT_DIR_PATH}${CLEAR_TEXT} is valid and does not contain syntax errors."
        echo -e "  - The current user has sufficient permissions to access ${COMMAND_TEXT}${SCRIPT_DIR_PATH}${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_FAILED_CD"
    fi
}

# Name: 'waCheckInput'
# Role: Sanitises input and guides users through selecting appropriate options if no arguments are provided.
function waCheckInput() {
    # Declare variables.
    local OPTIONS=()      # Stores the options.
    local SELECTED_OPTION # Stores the option selected by the user.

    if [[ $# -gt 0 ]]; then
        # Parse arguments.
        for argument in "$@"; do
            case "$argument" in
            "--user")
                OPT_USER=1
                ;;
            "--system")
                OPT_SYSTEM=1
                ;;
            "--setupAllOfficiallySupportedApps")
                OPT_AOSA=1
                ;;
            "--uninstall")
                OPT_UNINSTALL=1
                ;;
            "--help")
                waUsage
                exit 0
                ;;
            *)
                # Display the error type.
                echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}INVALID ARGUMENT.${CLEAR_TEXT}"

                # Display the error details.
                echo -e "${INFO_TEXT}Unsupported argument${CLEAR_TEXT} ${COMMAND_TEXT}${argument}${CLEAR_TEXT}${INFO_TEXT}.${CLEAR_TEXT}"

                # Display the suggested action(s).
                echo "--------------------------------------------------------------------------------"
                waUsage
                echo "--------------------------------------------------------------------------------"

                # Terminate the script.
                return "$EC_BAD_ARGUMENT"
                ;;
            esac
        done
    else
        # Install vs. uninstall?
        OPTIONS=("Install" "Uninstall")
        inqMenu "Install or uninstall WinApps?" OPTIONS SELECTED_OPTION

        # Set flags.
        if [[ $SELECTED_OPTION == "Uninstall" ]]; then
            OPT_UNINSTALL=1
        fi

        # User vs. system?
        OPTIONS=("Current User" "System")
        inqMenu "Configure WinApps for the current user '$(whoami)' or the whole system?" OPTIONS SELECTED_OPTION

        # Set flags.
        if [[ $SELECTED_OPTION == "Current User" ]]; then
            OPT_USER=1
        elif [[ $SELECTED_OPTION == "System" ]]; then
            OPT_SYSTEM=1
        fi

        # Automatic vs. manual?
        if [ "$OPT_UNINSTALL" -eq 0 ]; then
            OPTIONS=("Manual (Default)" "Automatic")
            inqMenu "Automatically install supported applications or choose manually?" OPTIONS SELECTED_OPTION

            # Set flags.
            if [[ $SELECTED_OPTION == "Automatic" ]]; then
                OPT_AOSA=1
            fi
        fi

        # Newline.
        echo ""
    fi

    # Simultaneous 'User' and 'System'.
    if [ "$OPT_SYSTEM" -eq 1 ] && [ "$OPT_USER" -eq 1 ]; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}CONFLICTING ARGUMENTS.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}You cannot specify both${CLEAR_TEXT} ${COMMAND_TEXT}--user${CLEAR_TEXT} ${INFO_TEXT}and${CLEAR_TEXT} ${COMMAND_TEXT}--system${CLEAR_TEXT} ${INFO_TEXT}simultaneously.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        waUsage
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_BAD_ARGUMENT"
    fi

    # Simultaneous 'Uninstall' and 'AOSA'.
    if [ "$OPT_UNINSTALL" -eq 1 ] && [ "$OPT_AOSA" -eq 1 ]; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}CONFLICTING ARGUMENTS.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}You cannot specify both${CLEAR_TEXT} ${COMMAND_TEXT}--uninstall${CLEAR_TEXT} ${INFO_TEXT}and${CLEAR_TEXT} ${COMMAND_TEXT}--aosa${CLEAR_TEXT} ${INFO_TEXT}simultaneously.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        waUsage
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_BAD_ARGUMENT"
    fi

    # No 'User' or 'System'.
    if [ "$OPT_SYSTEM" -eq 0 ] && [ "$OPT_USER" -eq 0 ]; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}INSUFFICIENT ARGUMENTS.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}You must specify either${CLEAR_TEXT} ${COMMAND_TEXT}--user${CLEAR_TEXT} ${INFO_TEXT}or${CLEAR_TEXT} ${COMMAND_TEXT}--system${CLEAR_TEXT} ${INFO_TEXT}to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        waUsage
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_BAD_ARGUMENT"
    fi
}

# Name: 'waConfigurePathsAndPermissions'
# Role: Sets paths and adjusts permissions as specified.
function waConfigurePathsAndPermissions() {
    if [ "$OPT_USER" -eq 1 ]; then
        SUDO=""
        BIN_PATH="$USER_BIN_PATH"
        APP_PATH="$USER_APP_PATH"
        APPDATA_PATH="$USER_APPDATA_PATH"
    elif [ "$OPT_SYSTEM" -eq 1 ]; then
        SUDO="sudo"
        BIN_PATH="$SYS_BIN_PATH"
        APP_PATH="$SYS_APP_PATH"
        APPDATA_PATH="$SYS_APPDATA_PATH"

        # Preemptively obtain superuser privileges.
        sudo -v || {
            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}AUTHENTICATION FAILURE.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}Failed to gain superuser privileges.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Please check your password and try again."
            echo "If you continue to experience issues, contact your system administrator."
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_NO_SUDO"
        }
    fi
}

# Name: 'waCheckExistingInstall'
# Role: Identifies any existing WinApps installations that may conflict with the new installation.
function waCheckExistingInstall() {
    # Print feedback.
    echo -n "Checking for existing conflicting WinApps installations... "

    # Check for an existing 'user' installation.
    if [ -f "${USER_BIN_PATH}/winapps" ]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}EXISTING 'USER' WINAPPS INSTALLATION.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}A previous WinApps installation was detected for the current user.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please remove the existing WinApps installation using ${COMMAND_TEXT}./installer.sh --user --uninstall${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_EXISTING_INSTALL"
    fi

    # Check for an existing 'system' installation.
    if [ -f "${SYS_BIN_PATH}/winapps" ]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}EXISTING 'SYSTEM' WINAPPS INSTALLATION.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}A previous system-wide WinApps installation was detected.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please remove the existing WinApps installation using ${COMMAND_TEXT}./installer.sh --system --uninstall${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_EXISTING_INSTALL"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waFixScale'
# Role: Since FreeRDP only supports '/scale' values of 100, 140 or 180, find the closest supported argument to the user's configuration.
function waFixScale() {
    # Define variables.
    local OLD_SCALE=100
    local VALID_SCALE_1=100
    local VALID_SCALE_2=140
    local VALID_SCALE_3=180

    # Check for an unsupported value.
    if [ "$RDP_SCALE" != "$VALID_SCALE_1" ] && [ "$RDP_SCALE" != "$VALID_SCALE_2" ] && [ "$RDP_SCALE" != "$VALID_SCALE_3" ]; then
        # Save the unsupported scale.
        OLD_SCALE="$RDP_SCALE"

        # Calculate the absolute differences.
        local DIFF_1=$(( RDP_SCALE > VALID_SCALE_1 ? RDP_SCALE - VALID_SCALE_1 : VALID_SCALE_1 - RDP_SCALE ))
        local DIFF_2=$(( RDP_SCALE > VALID_SCALE_2 ? RDP_SCALE - VALID_SCALE_2 : VALID_SCALE_2 - RDP_SCALE ))
        local DIFF_3=$(( RDP_SCALE > VALID_SCALE_3 ? RDP_SCALE - VALID_SCALE_3 : VALID_SCALE_3 - RDP_SCALE ))

        # Set the final scale to the valid scale value with the smallest absolute difference.
        if (( DIFF_1 <= DIFF_2 && DIFF_1 <= DIFF_3 )); then
            RDP_SCALE="$VALID_SCALE_1"
        elif (( DIFF_2 <= DIFF_1 && DIFF_2 <= DIFF_3 )); then
            RDP_SCALE="$VALID_SCALE_2"
        else
            RDP_SCALE="$VALID_SCALE_3"
        fi

        # Print feedback.
        echo -e "${WARNING_TEXT}[WARNING]${CLEAR_TEXT} Unsupported RDP_SCALE value '${OLD_SCALE}' detected. Defaulting to '${RDP_SCALE}'."
    fi
}

# Name: 'waLoadConfig'
# Role: Loads settings specified within the WinApps configuration file.
function waLoadConfig() {
    # Print feedback.
    echo -n "Attempting to load WinApps configuration file... "

    if [ ! -f "$CONFIG_PATH" ]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING CONFIGURATION FILE.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}A valid WinApps configuration file was not found.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please create a configuration file at ${COMMAND_TEXT}${CONFIG_PATH}${CLEAR_TEXT}."
        echo -e "See https://github.com/winapps-org/winapps?tab=readme-ov-file#step-3-create-a-winapps-configuration-file"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_NO_CONFIG"
    else
        # Load the WinApps configuration file.
        # shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
        source "$CONFIG_PATH"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waCheckScriptDependencies'
# Role: Terminate script if dependencies are missing.
function waCheckScriptDependencies() {
    # 'Dialog'.
    if ! command -v dialog &>/dev/null; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Please install 'dialog' to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Debian/Ubuntu-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo apt install dialog${CLEAR_TEXT}"
        echo "Red Hat/Fedora-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo dnf install dialog${CLEAR_TEXT}"
        echo "Arch Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo pacman -S dialog${CLEAR_TEXT}"
        echo "Gentoo Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo emerge --ask dialog${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_MISSING_DEPS"
    fi
}

# Name: 'waCheckInstallDependencies'
# Role: Terminate script if dependencies required to install WinApps are missing.
function waCheckInstallDependencies() {
    # Declare variables.
    local FREERDP_MAJOR_VERSION="" # Stores the major version of the installed copy of FreeRDP.

    # Print feedback.
    echo -n "Checking whether dependencies are installed... "

    # 'libnotify'
    if ! command -v notify-send &>/dev/null; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Please install 'libnotify' to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Debian/Ubuntu-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo apt install libnotify-bin${CLEAR_TEXT}"
        echo "Red Hat/Fedora-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo dnf install libnotify${CLEAR_TEXT}"
        echo "Arch Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo pacman -S libnotify${CLEAR_TEXT}"
        echo "Gentoo Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo emerge --ask x11-libs/libnotify${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_MISSING_DEPS"
    fi

    # 'Netcat'
    if ! command -v nc &>/dev/null; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Please install 'netcat' to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Debian/Ubuntu-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo apt install netcat${CLEAR_TEXT}"
        echo "Red Hat/Fedora-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo dnf install nmap-ncat${CLEAR_TEXT}"
        echo "Arch Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo pacman -S gnu-netcat${CLEAR_TEXT}"
        echo "Gentoo Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo emerge --ask net-analyzer/netcat${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_MISSING_DEPS"
    fi

    # 'FreeRDP' (Version 3).
    # Attempt to set a FreeRDP command if the command variable is empty.
    if [ -z "$FREERDP_COMMAND" ]; then
        # Check common commands used to launch FreeRDP.
        if command -v xfreerdp &>/dev/null; then
            # Check FreeRDP major version is 3 or greater.
            FREERDP_MAJOR_VERSION=$(xfreerdp --version | head -n 1 | grep -o -m 1 '\b[0-9]\S*' | head -n 1 | cut -d'.' -f1)
            if [[ $FREERDP_MAJOR_VERSION =~ ^[0-9]+$ ]] && ((FREERDP_MAJOR_VERSION >= 3)); then
                FREERDP_COMMAND="xfreerdp"
            fi
        elif command -v xfreerdp3 &>/dev/null; then
            # Check FreeRDP major version is 3 or greater.
            FREERDP_MAJOR_VERSION=$(xfreerdp3 --version | head -n 1 | grep -o -m 1 '\b[0-9]\S*' | head -n 1 | cut -d'.' -f1)
            if [[ $FREERDP_MAJOR_VERSION =~ ^[0-9]+$ ]] && ((FREERDP_MAJOR_VERSION >= 3)); then
                FREERDP_COMMAND="xfreerdp3"
            fi
        fi

        # Check for FreeRDP flatpak as a fallback option.
        if [ -z "$FREERDP_COMMAND" ]; then
            if command -v flatpak &>/dev/null; then
                if flatpak list --columns=application | grep -q "^com.freerdp.FreeRDP$"; then
                    # Check FreeRDP major version is 3 or greater.
                    FREERDP_MAJOR_VERSION=$(flatpak list --columns=application,version | grep "^com.freerdp.FreeRDP" | awk '{print $2}' | cut -d'.' -f1)
                    if [[ $FREERDP_MAJOR_VERSION =~ ^[0-9]+$ ]] && ((FREERDP_MAJOR_VERSION >= 3)); then
                        FREERDP_COMMAND="flatpak run --command=xfreerdp com.freerdp.FreeRDP"
                    fi
                fi
            fi
        fi
    fi

    if ! command -v "$FREERDP_COMMAND" &>/dev/null && [ "$FREERDP_COMMAND" != "flatpak run --command=xfreerdp com.freerdp.FreeRDP" ]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Please install 'FreeRDP' version 3 to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Debian/Ubuntu-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo apt install freerdp3-x11${CLEAR_TEXT}"
        echo "Red Hat/Fedora-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo dnf install freerdp${CLEAR_TEXT}"
        echo "Arch Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo pacman -S freerdp${CLEAR_TEXT}"
        echo "Gentoo Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo emerge --ask net-misc/freerdp${CLEAR_TEXT}"
        echo ""
        echo "You can also install FreeRDP as a Flatpak."
        echo "Install Flatpak, add the Flathub repository and then install FreeRDP:"
        echo -e "${COMMAND_TEXT}flatpak install flathub com.freerdp.FreeRDP${CLEAR_TEXT}"
        echo -e "${COMMAND_TEXT}sudo flatpak override --filesystem=home com.freerdp.FreeRDP${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_MISSING_DEPS"
    fi

    # 'libvirt'/'virt-manager' + 'iproute2'.
    if [ "$WAFLAVOR" = "libvirt" ]; then
        if ! command -v virsh &>/dev/null; then
            # Complete the previous line.
            echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}Please install 'Virtual Machine Manager' to proceed.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Debian/Ubuntu-based systems:"
            echo -e "  ${COMMAND_TEXT}sudo apt install virt-manager${CLEAR_TEXT}"
            echo "Red Hat/Fedora-based systems:"
            echo -e "  ${COMMAND_TEXT}sudo dnf install virt-manager${CLEAR_TEXT}"
            echo "Arch Linux systems:"
            echo -e "  ${COMMAND_TEXT}sudo pacman -S virt-manager${CLEAR_TEXT}"
            echo "Gentoo Linux systems:"
            echo -e "  ${COMMAND_TEXT}sudo emerge --ask app-emulation/virt-manager${CLEAR_TEXT}"
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_MISSING_DEPS"
        fi

        if ! command -v ip &>/dev/null; then
            # Complete the previous line.
            echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}Please install 'iproute2' to proceed.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Debian/Ubuntu-based systems:"
            echo -e "  ${COMMAND_TEXT}sudo apt install iproute2${CLEAR_TEXT}"
            echo "Red Hat/Fedora-based systems:"
            echo -e "  ${COMMAND_TEXT}sudo dnf install iproute${CLEAR_TEXT}"
            echo "Arch Linux systems:"
            echo -e "  ${COMMAND_TEXT}sudo pacman -S iproute2${CLEAR_TEXT}"
            echo "Gentoo Linux systems:"
            echo -e "  ${COMMAND_TEXT}sudo emerge --ask net-misc/iproute2${CLEAR_TEXT}"
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_MISSING_DEPS"
        fi
    elif [ "$WAFLAVOR" = "docker" ]; then
        if ! command -v docker &>/dev/null; then
            # Complete the previous line.
            echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}Please install 'Docker Engine' to proceed.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Please visit https://docs.docker.com/engine/install/ for more information."
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_MISSING_DEPS"
        fi
    elif [ "$WAFLAVOR" = "podman" ]; then
        if ! command -v podman-compose &>/dev/null || ! command -v podman &>/dev/null; then
            # Complete the previous line.
            echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}Please install 'podman' and 'podman-compose' to proceed.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Please visit https://podman.io/docs/installation for more information."
            echo "Please visit https://github.com/containers/podman-compose for more information."
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_MISSING_DEPS"
        fi
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waCheckGroupMembership'
# Role: Ensures the current user is part of the required groups.
function waCheckGroupMembership() {
    # Print feedback.
    echo -n "Checking whether the user '$(whoami)' is part of the required groups... "

    # Declare variables.
    local USER_GROUPS="" # Stores groups the current user belongs to.

    # Identify groups the current user belongs to.
    USER_GROUPS=$(groups "$(whoami)")

    if ! (echo "$USER_GROUPS" | grep -q -E "\blibvirt\b") || ! (echo "$USER_GROUPS" | grep -q -E "\bkvm\b"); then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}GROUP MEMBERSHIP CHECK ERROR.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}The current user '$(whoami)' is not part of group 'libvirt' and/or group 'kvm'.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please run the below commands, followed by a system reboot:"
        echo -e "${COMMAND_TEXT}sudo usermod -a -G libvirt $(whoami)${CLEAR_TEXT}"
        echo -e "${COMMAND_TEXT}sudo usermod -a -G kvm $(whoami)${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_NOT_IN_GROUP"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waCheckVMRunning'
# Role: Checks the state of the Windows 'libvirt' VM to ensure it is running.
function waCheckVMRunning() {
    # Print feedback.
    echo -n "Checking the status of the Windows VM... "

    # Declare variables.
    local VM_STATE="" # Stores the state of the Windows VM.

    # Obtain VM Status
    VM_STATE=$(virsh list --all | grep -w "$VM_NAME")

    if [[ $VM_STATE == *"shut off"* ]]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}WINDOWS VM NOT RUNNING.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}The Windows VM '${VM_NAME}' is powered off.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please run the below command to start the Windows VM:"
        echo -e "${COMMAND_TEXT}virsh start ${VM_NAME}${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_VM_OFF"
    elif [[ $VM_STATE == *"paused"* ]]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}WINDOWS VM NOT RUNNING.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}The Windows VM '${VM_NAME}' is paused.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please run the below command to resume the Windows VM:"
        echo -e "${COMMAND_TEXT}virsh resume ${VM_NAME}${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_VM_PAUSED"
    elif [[ $VM_STATE != *"running"* ]]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}WINDOWS VM DOES NOT EXIST.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}The Windows VM '${VM_NAME}' could not be found.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please ensure a Windows VM with the name '${VM_NAME}' exists."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_VM_ABSENT"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waCheckContainerRunning'
# Role: Throw an error if the Docker/Podman container is not running.
function waCheckContainerRunning() {
    # Print feedback.
    echo -n "Checking container status... "

    # Declare variables.
    local CONTAINER_STATE=""
    local COMPOSE_COMMAND=""

    # Determine the state of the container.
    CONTAINER_STATE=$("$WAFLAVOR" ps --all --filter name="WinApps" --format '{{.Status}}')
    CONTAINER_STATE=${CONTAINER_STATE,,} # Convert the string to lowercase.
    CONTAINER_STATE=${CONTAINER_STATE%% *} # Extract the first word.

    # Determine the compose command.
    case "$WAFLAVOR" in
        "docker") COMPOSE_COMMAND="docker compose" ;;
        "podman") COMPOSE_COMMAND="podman-compose" ;;
    esac

    # Check container state.
    if [[ "$CONTAINER_STATE" != "up" ]]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}CONTAINER NOT RUNNING.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Windows is not running.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please ensure Windows is powered on:"
        echo -e "${COMMAND_TEXT}${COMPOSE_COMMAND} --file ~/.config/winapps/winapps.conf start${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_CONTAINER_OFF"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waCheckPortOpen'
# Role: Assesses whether the RDP port on Windows is open.
function waCheckPortOpen() {
    # Print feedback.
    echo -n "Checking for an open RDP Port on Windows... "

    # Declare variables.
    local VM_MAC="" # Stores the MAC address of the Windows VM.

    # Obtain Windows VM IP Address (FOR 'libvirt' ONLY)
    # Note: 'RDP_IP' should not be empty if 'WAFLAVOR' is 'docker', since it is set to localhost before this function is called.
    if [ -z "$RDP_IP" ] && [ "$WAFLAVOR" = "libvirt" ]; then
        VM_MAC=$(virsh domiflist "$VM_NAME" | grep -oE "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") # VM MAC address.
        RDP_IP=$(ip neigh show | grep "$VM_MAC" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")         # VM IP address.

        if [ -z "$RDP_IP" ]; then
            # Complete the previous line.
            echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}NETWORK CONFIGURATION ERROR.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}The IP address of the Windows VM '${VM_NAME}' could not be found.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Please ensure networking is properly configured for the Windows VM."
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_NO_IP"
        fi
    fi

    # Check for an open RDP port.
    if ! timeout 5 nc -z "$RDP_IP" "$RDP_PORT" &>/dev/null; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}NETWORK CONFIGURATION ERROR.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Failed to establish a connection with Windows at '${RDP_IP}:${RDP_PORT}'.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please ensure Remote Desktop is configured on Windows as per the WinApps README."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_BAD_PORT"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waCheckRDPAccess'
# Role: Tests if Windows is accessible via RDP.
function waCheckRDPAccess() {
    # Print feedback.
    echo -n "Attempting to establish a Remote Desktop connection with Windows... "

    # Declare variables.
    local FREERDP_LOG=""  # Stores the path of the FreeRDP log file.
    local FREERDP_PROC="" # Stores the FreeRDP process ID.
    local ELAPSED_TIME="" # Stores the time counter.

    # Log file path.
    FREERDP_LOG="${USER_APPDATA_PATH}/FreeRDP_Test_$(date +'%Y%m%d_%H%M_%N').log"

    # Ensure the output directory exists.
    mkdir -p "$USER_APPDATA_PATH"

    # Remove existing 'FreeRDP Connection Test' file.
    rm -f "$TEST_PATH"

    # This command should create a file on the host filesystem before terminating the RDP session. This command is silently executed as a background process.
    # If the file is created, it means Windows received the command via FreeRDP successfully and can read and write to the Linux home folder.
    # Note: The following final line is expected within the log, indicating successful execution of the 'tsdiscon' command and termination of the RDP session.
    # [INFO][com.freerdp.core] - [rdp_print_errinfo]: ERRINFO_LOGOFF_BY_USER (0x0000000C):The disconnection was initiated by the user logging off their session on the server.
    # shellcheck disable=SC2140,SC2027 # Disable warnings regarding unquoted strings.
    $FREERDP_COMMAND \
        /cert:tofu \
        /d:"$RDP_DOMAIN" \
        /u:"$RDP_USER" \
        /p:"$RDP_PASS" \
        /scale:"$RDP_SCALE" \
        +auto-reconnect \
        +home-drive \
        -wallpaper \
        +dynamic-resolution \
        /app:program:"C:\Windows\System32\cmd.exe",cmd:"/C type NUL > "$TEST_PATH_WIN" && tsdiscon" \
        /v:"$RDP_IP" &>"$FREERDP_LOG" &

    # Store the FreeRDP process ID.
    FREERDP_PROC=$!

    # Initialise the time counter.
    ELAPSED_TIME=0

    # Wait a maximum of 30 seconds for the background process to complete.
    while [ "$ELAPSED_TIME" -lt 30 ]; do
        # Check if the FreeRDP process is complete or if the test file exists.
        if ! ps -p "$FREERDP_PROC" &>/dev/null || [ -f "$TEST_PATH" ]; then
            break
        fi

        # Wait for 5 seconds.
        sleep 5
        ELAPSED_TIME=$((ELAPSED_TIME + 5))
    done

    # Check if FreeRDP process is not complete.
    if ps -p "$FREERDP_PROC" &>/dev/null; then
        # SIGKILL FreeRDP.
        kill -9 "$FREERDP_PROC" &>/dev/null
    fi

    # Check if test file does not exist.
    if ! [ -f "$TEST_PATH" ]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}REMOTE DESKTOP PROTOCOL FAILURE.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}FreeRDP failed to establish a connection with Windows.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please view the log at ${COMMAND_TEXT}${FREERDP_LOG}${CLEAR_TEXT}."
        echo "Troubleshooting Tips:"
        echo "  - Ensure the user is logged out of Windows prior to initiating the WinApps installation."
        echo "  - Ensure the credentials within the WinApps configuration file are correct."
        echo -e "  - Utilise a new certificate by removing relevant certificate(s) in ${COMMAND_TEXT}${HOME}/.config/freerdp/server${CLEAR_TEXT}."
        echo "  - If using 'libvirt', ensure the Windows VM is correctly named as specified within the README."
        echo "  - If using 'libvirt', ensure 'Remote Desktop' is enabled within the Windows VM."
        echo "  - If using 'libvirt', ensure you have merged 'RDPApps.reg' into the Windows VM's registry."
        echo "  - If using 'libvirt', try logging into and back out of the Windows VM within 'virt-manager' prior to initiating the WinApps installation."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_RDP_FAIL"
    else
        # Remove the temporary test file.
        rm -f "$TEST_PATH"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waFindInstalled'
# Role: Identifies installed applications on Windows.
function waFindInstalled() {
    # Print feedback.
    echo -n "Checking for installed Windows applications... "

    # Declare variables.
    local FREERDP_LOG=""  # Stores the path of the FreeRDP log file.
    local FREERDP_PROC="" # Stores the FreeRDP process ID.
    local ELAPSED_TIME="" # Stores the time counter.

    # Log file path.
    FREERDP_LOG="${USER_APPDATA_PATH}/FreeRDP_Scan_$(date +'%Y%m%d_%H%M_%N').log"

    # Make the output directory if required.
    mkdir -p "$USER_APPDATA_PATH"

    # Remove temporary files from previous WinApps installations.
    rm -f "$BATCH_SCRIPT_PATH" "$TMP_INST_FILE_PATH" "$INST_FILE_PATH" "$PS_SCRIPT_HOME_PATH" "$DETECTED_FILE_PATH"

    # Copy PowerShell script to a directory within the user's home folder.
    # This will enable the PowerShell script to be accessed and executed by Windows.
    cp "$PS_SCRIPT_PATH" "$PS_SCRIPT_HOME_PATH"

    # Enumerate over each officially supported application.
    for APPLICATION in ./apps/*; do
        # Extract the name of the application from the absolute path of the folder.
        APPLICATION="$(basename "$APPLICATION")"

        # Source 'Info' File Containing:
        # - The Application Name          (FULL_NAME)
        # - The Shortcut Name             (NAME)
        # - Application Categories        (CATEGORIES)
        # - Executable Path               (WIN_EXECUTABLE)
        # - Supported MIME Types          (MIME_TYPES)
        # - Application Icon              (ICON)
        # shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
        source "./apps/${APPLICATION}/info"

        # Append commands to batch file.
        echo "IF EXIST \"${WIN_EXECUTABLE}\" ECHO ${APPLICATION} >> ${TMP_INST_FILE_PATH_WIN}" >>"$BATCH_SCRIPT_PATH"
    done

    # Append a command to the batch script to run the PowerShell script and store it's output in the 'detected' file.
    # shellcheck disable=SC2129 # Silence warning regarding repeated redirects.
    echo "powershell.exe -ExecutionPolicy Bypass -File ${PS_SCRIPT_HOME_PATH_WIN} > ${DETECTED_FILE_PATH_WIN}" >>"$BATCH_SCRIPT_PATH"

    # Append a command to the batch script to rename the temporary file containing the names of all detected officially supported applications.
    echo "RENAME ${TMP_INST_FILE_PATH_WIN} installed" >>"$BATCH_SCRIPT_PATH"

    # Append a command to the batch script to terminate the remote desktop session once all previous commands are complete.
    echo "tsdiscon" >>"$BATCH_SCRIPT_PATH"

    # Silently execute the batch script within Windows in the background (Log Output To File)
    # Note: The following final line is expected within the log, indicating successful execution of the 'tsdiscon' command and termination of the RDP session.
    # [INFO][com.freerdp.core] - [rdp_print_errinfo]: ERRINFO_LOGOFF_BY_USER (0x0000000C):The disconnection was initiated by the user logging off their session on the server.
    # shellcheck disable=SC2140,SC2027 # Disable warnings regarding unquoted strings.
    $FREERDP_COMMAND \
        /cert:tofu \
        /d:"$RDP_DOMAIN" \
        /u:"$RDP_USER" \
        /p:"$RDP_PASS" \
        /scale:"$RDP_SCALE" \
        +auto-reconnect \
        +home-drive \
        -wallpaper \
        +dynamic-resolution \
        /app:program:"C:\Windows\System32\cmd.exe",cmd:"/C "$BATCH_SCRIPT_PATH_WIN"" \
        /v:"$RDP_IP" &>"$FREERDP_LOG" &

    # Store the FreeRDP process ID.
    FREERDP_PROC=$!

    # Initialise the time counter.
    ELAPSED_TIME=0

    # Wait a maximum of 60 seconds for the batch script to finish running.
    while [ $ELAPSED_TIME -lt 60 ]; do
        # Check if the FreeRDP process is complete or if the 'installed' file exists.
        if ! ps -p "$FREERDP_PROC" &>/dev/null || [ -f "$INST_FILE_PATH" ]; then
            break
        fi

        # Wait for 5 seconds.
        sleep 5
        ELAPSED_TIME=$((ELAPSED_TIME + 5))
    done

    # Check if the FreeRDP process is not complete.
    if ps -p "$FREERDP_PROC" &>/dev/null; then
        # SIGKILL FreeRDP.
        kill -9 "$FREERDP_PROC" &>/dev/null
    fi

    # Check if test file does not exist.
    if ! [ -f "$INST_FILE_PATH" ]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}APPLICATION QUERY FAILURE.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Failed to query Windows for installed applications.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please view the log at ${COMMAND_TEXT}${FREERDP_LOG}${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_APPQUERY_FAIL"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waConfigureWindows'
# Role: Create an application entry for launching Windows via Remote Desktop.
function waConfigureWindows() {
    # Print feedback.
    echo -n "Creating an application entry for Windows... "

    # Declare variables.
    local WIN_BASH=""    # Stores the bash script to launch a Windows RDP session.
    local WIN_DESKTOP="" # Stores the '.desktop' file to launch a Windows RDP session.

    # Populate variables.
    WIN_BASH="\
#!/usr/bin/env bash
${BIN_PATH}/winapps windows"
    WIN_DESKTOP="\
[Desktop Entry]
Name=Windows
Exec=${BIN_PATH}/winapps windows %F
Terminal=false
Type=Application
Icon=${APPDATA_PATH}/icons/windows.svg
StartupWMClass=Microsoft Windows
Comment=Microsoft Windows RDP Session"

    # Copy the 'Windows' icon.
    $SUDO cp "./icons/windows.svg" "${APPDATA_PATH}/icons/windows.svg"

    # Write the desktop entry content to a file.
    echo "$WIN_DESKTOP" | $SUDO tee "${APP_PATH}/windows.desktop" &>/dev/null

    # Write the bash script to a file.
    echo "$WIN_BASH" | $SUDO tee "${BIN_PATH}/windows" &>/dev/null

    # Mark the bash script as executable.
    $SUDO chmod a+x "${BIN_PATH}/windows"

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waConfigureApp'
# Role: Create application entries for a given application installed on Windows.
function waConfigureApp() {
    # Declare variables.
    local APP_ICON=""         # Stores the path to the application icon.
    local APP_BASH=""         # Stores the bash script used to launch the application.
    local APP_DESKTOP_FILE="" # Stores the '.desktop' file used to launch the application.

    # Source 'Info' File Containing:
    # - The Application Name          (FULL_NAME)
    # - The Shortcut Nsame            (NAME)
    # - Application Categories        (CATEGORIES)
    # - Executable Path               (WIN_EXECUTABLE)
    # - Supported MIME Types          (MIME_TYPES)
    # - Application Icon              (ICON)
    # shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
    source "${APPDATA_PATH}/apps/${1}/info"

    # Determine path to application icon using arguments passed to function.
    APP_ICON="${APPDATA_PATH}/apps/${1}/icon.${2}"

    # Determine the content of the bash script for the application.
    APP_BASH="\
#!/usr/bin/env bash
${BIN_PATH}/winapps ${1}"

    # Determine the content of the '.desktop' file for the application.
    APP_DESKTOP_FILE="\
[Desktop Entry]
Name=${NAME}
Exec=${BIN_PATH}/winapps ${1} %F
Terminal=false
Type=Application
Icon=${APP_ICON}
StartupWMClass=${FULL_NAME}
Comment=${FULL_NAME}
Categories=${CATEGORIES}
MimeType=${MIME_TYPES}"

    # Store the '.desktop' file for the application.
    echo "$APP_DESKTOP_FILE" | $SUDO tee "${APP_PATH}/${1}.desktop" &>/dev/null

    # Store the bash script for the application.
    echo "$APP_BASH" | $SUDO tee "${BIN_PATH}/${1}" &>/dev/null

    # Mark bash script as executable.
    $SUDO chmod a+x "${BIN_PATH}/${1}"
}

# Name: 'waConfigureOfficiallySupported'
# Role: Create application entries for officially supported applications installed on Windows.
function waConfigureOfficiallySupported() {
    # Declare variables.
    local OSA_LIST=() # Stores a list of all officially supported applications installed on Windows.

    # Read the list of officially supported applications that are installed on Windows into an array, returning an empty array if no such files exist.
    # This will remove leading and trailing whitespace characters as well as ignore empty lines.
    readarray -t OSA_LIST < <(grep -v '^[[:space:]]*$' "$INST_FILE_PATH" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' 2>/dev/null || true)

    # Create application entries for each officially supported application.
    for OSA in "${OSA_LIST[@]}"; do
        # Print feedback.
        echo -n "Creating an application entry for ${OSA}... "

        # Copy application icon and information.
        $SUDO cp -r "./apps/${OSA}" "${APPDATA_PATH}/apps"

        # Configure the application.
        waConfigureApp "$OSA" svg

        # Print feedback.
        echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
    done

    # Delete 'install' file.
    rm -f "$INST_FILE_PATH"
}

# Name: 'waConfigureApps'
# Role: Allow the user to select which officially supported applications to configure.
function waConfigureApps() {
    # Declare variables.
    local OSA_LIST=()      # Stores a list of all officially supported applications installed on Windows.
    local APPS=()          # Stores a list of both the simplified and full names of each installed officially supported application.
    local OPTIONS=()       # Stores a list of options presented to the user.
    local APP_INSTALL=""   # Stores the option selected by the user.
    local SELECTED_APPS=() # Stores the officially supported applications selected by the user.
    local TEMP_ARRAY=()    # Temporary array used for sorting elements of an array.

    # Read the list of officially supported applications that are installed on Windows into an array, returning an empty array if no such files exist.
    # This will remove leading and trailing whitespace characters as well as ignore empty lines.
    readarray -t OSA_LIST < <(grep -v '^[[:space:]]*$' "$INST_FILE_PATH" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' 2>/dev/null || true)

    # Loop over each officially supported application installed on Windows.
    for OSA in "${OSA_LIST[@]}"; do
        # Source 'Info' File Containing:
        # - The Application Name          (FULL_NAME)
        # - The Shortcut Nsame            (NAME)
        # - Application Categories        (CATEGORIES)
        # - Executable Path               (WIN_EXECUTABLE)
        # - Supported MIME Types          (MIME_TYPES)
        # - Application Icon              (ICON)
        # shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
        source "./apps/${OSA}/info"

        # Add both the simplified and full name of the application to an array.
        APPS+=("${FULL_NAME} (${OSA})")

        # Extract the executable file name (e.g. 'MyApp.exe') from the absolute path.
        WIN_EXECUTABLE="${WIN_EXECUTABLE##*\\}"

        # Trim any leading or trailing whitespace characters from the executable file name.
        read -r WIN_EXECUTABLE <<<"$(echo "$WIN_EXECUTABLE" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

        # Add the executable file name (in lowercase) to the array.
        INSTALLED_EXES+=("${WIN_EXECUTABLE,,}")
    done

    # Sort the 'APPS' array in alphabetical order.
    IFS=$'\n'
    # shellcheck disable=SC2207 # Silence warnings regarding preferred use of 'mapfile' or 'read -a'.
    TEMP_ARRAY=($(sort <<<"${APPS[*]}"))
    unset IFS
    APPS=("${TEMP_ARRAY[@]}")

    # Prompt user to select which officially supported applications to configure.
    OPTIONS=(
        "Set up all detected officially supported applications"
        "Choose specific officially supported applications to set up"
        "Skip setting up any officially supported applications"
    )
    inqMenu "How would you like to handle officially supported applications?" OPTIONS APP_INSTALL

    # Remove unselected officially supported applications from the 'install' file.
    if [[ $APP_INSTALL == "Choose specific officially supported applications to set up" ]]; then
        inqChkBx "Which officially supported applications would you like to set up?" APPS SELECTED_APPS

        # Clear/create the 'install' file.
        echo "" >"$INST_FILE_PATH"

        # Add each selected officially supported application back to the 'install' file.
        for SELECTED_APP in "${SELECTED_APPS[@]}"; do
            # Capture the substring within (but not including) the parentheses.
            # This substring represents the officially supported application name (see above loop).
            SELECTED_APP="${SELECTED_APP##*(}"
            SELECTED_APP="${SELECTED_APP%%)}"

            # Add the substring back to the 'install' file.
            echo "$SELECTED_APP" >>"$INST_FILE_PATH"
        done
    fi

    # Configure selected (or all) officially supported applications.
    if [[ $APP_INSTALL != "Skip setting up any officially supported applications" ]]; then
        waConfigureOfficiallySupported
    fi
}

# Name: 'waConfigureDetectedApps'
# Role: Allow the user to select which detected applications to configure.
function waConfigureDetectedApps() {
    # Declare variables.
    local APPS=()                   # Stores a list of both the simplified and full names of each detected application.
    local EXE_FILENAME=""           # Stores the executable filename of a given detected application.
    local EXE_FILENAME_NOEXT=""     # Stores the executable filename without the file extension of a given detected application.
    local EXE_FILENAME_LOWERCASE="" # Stores the executable filename of a given detected application in lowercase letters only.
    local OPTIONS=()                # Stores a list of options presented to the user.
    local APP_INSTALL=""            # Stores the option selected by the user.
    local SELECTED_APPS=()          # Detected applications selected by the user.
    local APP_DESKTOP_FILE=""       # Stores the '.desktop' file used to launch the application.
    local TEMP_ARRAY=()             # Temporary array used for sorting elements of an array.

    if [ -f "$DETECTED_FILE_PATH" ]; then
        # On UNIX systems, lines are terminated with a newline character (\n).
        # On WINDOWS systems, lines are terminated with both a carriage return (\r) and a newline (\n) character.
        # Remove all carriage returns (\r) within the 'detected' file, as the file was written by Windows.
        sed -i 's/\r//g' "$DETECTED_FILE_PATH"

        # Import the detected application information:
        # - Application Names               (NAMES)
        # - Application Icons in base64     (ICONS)
        # - Application Executable Paths    (EXES)
        # shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
        source "$DETECTED_FILE_PATH"

        # shellcheck disable=SC2153 # Silence warnings regarding possible misspellings.
        for INDEX in "${!NAMES[@]}"; do
            # Extract the executable file name (e.g. 'MyApp.exe').
            EXE_FILENAME=${EXES[$INDEX]##*\\}

            # Convert the executable file name to lower-case (e.g. 'myapp.exe').
            EXE_FILENAME_LOWERCASE="${EXE_FILENAME,,}"

            # Remove the file extension (e.g. 'MyApp').
            EXE_FILENAME_NOEXT="${EXE_FILENAME%.*}"

            # Check if the executable was previously configured as part of setting up officially supported applications.
            if [[ " ${INSTALLED_EXES[*]} " != *" ${EXE_FILENAME_LOWERCASE} "* ]]; then
                # If not previously configured, add the application to the list of detected applications.
                APPS+=("${NAMES[$INDEX]} (${EXE_FILENAME_NOEXT})")
            fi
        done

        # Sort the 'APPS' array in alphabetical order.
        IFS=$'\n'
        # shellcheck disable=SC2207 # Silence warnings regarding preferred use of 'mapfile' or 'read -a'.
        TEMP_ARRAY=($(sort <<<"${APPS[*]}"))
        unset IFS
        APPS=("${TEMP_ARRAY[@]}")

        # Prompt user to select which other detected applications to configure.
        OPTIONS=(
            "Set up all detected applications"
            "Select which applications to set up"
            "Do not set up any applications"
        )
        inqMenu "How would you like to handle other detected applications?" OPTIONS APP_INSTALL

        # Store selected detected applications.
        if [[ $APP_INSTALL == "Select which applications to set up" ]]; then
            inqChkBx "Which other applications would you like to set up?" APPS SELECTED_APPS
        elif [[ $APP_INSTALL == "Set up all detected applications" ]]; then
            for APP in "${APPS[@]}"; do
                SELECTED_APPS+=("$APP")
            done
        fi

        for SELECTED_APP in "${SELECTED_APPS[@]}"; do
            # Capture the substring within (but not including) the parentheses.
            # This substring represents the executable filename without the file extension (see above loop).
            EXE_FILENAME_NOEXT="${SELECTED_APP##*(}"
            EXE_FILENAME_NOEXT="${EXE_FILENAME_NOEXT%%)}"

            # Capture the substring prior to the space and parentheses.
            # This substring represents the detected application name (see above loop).
            PROGRAM_NAME="${SELECTED_APP% (*}"

            # Loop through all detected applications to find the detected application being processed.
            for INDEX in "${!NAMES[@]}"; do
                # Check for a matching detected application entry.
                if [[ ${NAMES[$INDEX]} == "$PROGRAM_NAME" ]] && [[ ${EXES[$INDEX]} == *"\\$EXE_FILENAME_NOEXT"* ]]; then
                    # Print feedback.
                    echo -n "Creating an application entry for ${PROGRAM_NAME}... "

                    # Create directory to store application icon and information.
                    $SUDO mkdir -p "${APPDATA_PATH}/apps/${EXE_FILENAME_NOEXT}"

                    # Determine the content of the '.desktop' file for the application.
                    APP_DESKTOP_FILE="\
# GNOME Shortcut Name
NAME=\"${PROGRAM_NAME}\"
# Used for Descriptions and Window Class
FULL_NAME=\"${PROGRAM_NAME}\"
# Path to executable inside Windows
WIN_EXECUTABLE=\"${EXES[$INDEX]}\"
# GNOME Categories
CATEGORIES=\"WinApps\"
# GNOME MIME Types
MIME_TYPES=\"\""

                    # Store the '.desktop' file for the application.
                    echo "$APP_DESKTOP_FILE" | $SUDO tee "${APPDATA_PATH}/apps/${EXE_FILENAME_NOEXT}/info" &>/dev/null

                    # Write application icon to file.
                    echo "${ICONS[$INDEX]}" | base64 -d | $SUDO tee "${APPDATA_PATH}/apps/${EXE_FILENAME_NOEXT}/icon.png" &>/dev/null

                    # Configure the application.
                    waConfigureApp "$EXE_FILENAME_NOEXT" png

                    # Print feedback.
                    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
                fi
            done
        done
    fi
}

# Name: 'waInstall'
# Role: Installs WinApps.
function waInstall() {
    # Print feedback.
    echo -e "${BOLD_TEXT}Installing WinApps.${CLEAR_TEXT}"

    # Check for existing conflicting WinApps installations.
    waCheckExistingInstall

    # Load the WinApps configuration file.
    waLoadConfig

    # Check for missing dependencies.
    waCheckInstallDependencies

    # Update $MULTI_FLAG.
    if [[ $MULTIMON == "true" ]]; then
        MULTI_FLAG="/multimon"
    else
        MULTI_FLAG="+span"
    fi

    # Update $RDP_SCALE.
    waFixScale

    # Append additional FreeRDP flags if required.
    if [[ -n $RDP_FLAGS ]]; then
        FREERDP_COMMAND="${FREERDP_COMMAND} ${RDP_FLAGS}"
    fi

    # If using 'docker' or 'podman', set RDP_IP to localhost.
    if [ "$WAFLAVOR" = "docker" ] || [ "$WAFLAVOR" = "podman" ]; then
        RDP_IP="$DOCKER_IP"
    fi

    # If using podman backend, modify the FreeRDP command to enter a new namespace.
    if [ "$WAFLAVOR" = "podman" ]; then
        FREERDP_COMMAND="podman unshare --rootless-netns ${FREERDP_COMMAND}"
    fi

    if [ "$WAFLAVOR" = "docker" ] || [ "$WAFLAVOR" = "podman" ]; then
        # Check if Windows is powered on.
        waCheckContainerRunning
    elif [ "$WAFLAVOR" = "libvirt" ]; then
        # Verify the current user's group membership.
        waCheckGroupMembership

        # Check if the Windows VM is powered on.
        waCheckVMRunning
    else
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}INVALID WINAPPS BACKEND.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}An invalid WinApps backend '${WAFLAVOR}' was specified.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please ensure 'WAFLAVOR' is set to 'docker', 'podman' or 'libvirt' in ${COMMAND_TEXT}${CONFIG_PATH}${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_INVALID_FLAVOR"
    fi

    # Check if the RDP port on Windows is open.
    waCheckPortOpen

    # Test RDP access to Windows.
    waCheckRDPAccess

    # Create required directories.
    $SUDO mkdir -p "$BIN_PATH"
    $SUDO mkdir -p "$APP_PATH"
    $SUDO mkdir -p "$APPDATA_PATH/apps"
    $SUDO mkdir -p "$APPDATA_PATH/icons"

    # Check for installed applications.
    waFindInstalled

    # Install the WinApps bash script.
    $SUDO cp "./bin/winapps" "${BIN_PATH}/winapps"

    # Configure the Windows RDP session application launcher.
    waConfigureWindows

    if [ "$OPT_AOSA" -eq 1 ]; then
        # Automatically configure all officially supported applications.
        waConfigureOfficiallySupported
    else
        # Configure officially supported applications.
        waConfigureApps

        # Configure other detected applications.
        waConfigureDetectedApps
    fi

    # Print feedback.
    echo -e "${SUCCESS_TEXT}INSTALLATION COMPLETE.${CLEAR_TEXT}"
}

# Name: 'waUninstall'
# Role: Uninstalls WinApps.
function waUninstall() {
    # Print feedback.
    [ "$OPT_SYSTEM" -eq 1 ] && echo -e "${BOLD_TEXT}REMOVING SYSTEM INSTALLATION.${CLEAR_TEXT}"
    [ "$OPT_USER" -eq 1 ] && echo -e "${BOLD_TEXT}REMOVING USER INSTALLATION.${CLEAR_TEXT}"

    # Declare variables.
    local WINAPPS_DESKTOP_FILES=()    # Stores a list of '.desktop' file paths.
    local WINAPPS_APP_BASH_SCRIPTS=() # Stores a list of bash script paths.
    local DESKTOP_FILE_NAME=""        # Stores the name of the '.desktop' file for the application.
    local BASH_SCRIPT_NAME=""         # Stores the name of the application.

    # Remove the 'WinApps' bash script.
    $SUDO rm -f "${BIN_PATH}/winapps"

    # Remove WinApps configuration data, temporary files and logs.
    rm -rf "$USER_APPDATA_PATH"

    # Remove application icons and shortcuts.
    $SUDO rm -rf "$APPDATA_PATH"

    # Store '.desktop' files containing "${BIN_PATH}/winapps" in an array, returning an empty array if no such files exist.
    readarray -t WINAPPS_DESKTOP_FILES < <(grep -l -d skip "${BIN_PATH}/winapps" "${APP_PATH}/"* 2>/dev/null || true)

    # Remove each '.desktop' file.
    for DESKTOP_FILE_PATH in "${WINAPPS_DESKTOP_FILES[@]}"; do
        # Trim leading and trailing whitespace from '.desktop' file path.
        DESKTOP_FILE_PATH=$(echo "$DESKTOP_FILE_PATH" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        # Extract the file name.
        DESKTOP_FILE_NAME=$(basename "$DESKTOP_FILE_PATH" | sed 's/\.[^.]*$//')

        # Print feedback.
        echo -n "Removing '.desktop' file for '${DESKTOP_FILE_NAME}'... "

        # Delete the file.
        $SUDO rm "$DESKTOP_FILE_PATH"

        # Print feedback.
        echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
    done

    # Store the paths of bash scripts calling 'WinApps' to launch specific applications in an array, returning an empty array if no such files exist.
    readarray -t WINAPPS_APP_BASH_SCRIPTS < <(grep -l -d skip "${BIN_PATH}/winapps" "${BIN_PATH}/"* 2>/dev/null || true)

    # Remove each bash script.
    for BASH_SCRIPT_PATH in "${WINAPPS_APP_BASH_SCRIPTS[@]}"; do
        # Trim leading and trailing whitespace from bash script path.
        BASH_SCRIPT_PATH=$(echo "$BASH_SCRIPT_PATH" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        # Extract the file name.
        BASH_SCRIPT_NAME=$(basename "$BASH_SCRIPT_PATH" | sed 's/\.[^.]*$//')

        # Print feedback.
        echo -n "Removing bash script for '${BASH_SCRIPT_NAME}'... "

        # Delete the file.
        $SUDO rm "$BASH_SCRIPT_PATH"

        # Print feedback.
        echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
    done

    # Print caveats.
    echo -e "\n${INFO_TEXT}Please note your WinApps configuration folder was not removed.${CLEAR_TEXT}"
    echo -e "${INFO_TEXT}You can remove this manually by running:${CLEAR_TEXT}"
    echo -e "${COMMAND_TEXT}rm -r $(dirname "$CONFIG_PATH")${CLEAR_TEXT}\n"

    # Print feedback.
    echo -e "${SUCCESS_TEXT}UNINSTALLATION COMPLETE.${CLEAR_TEXT}"
}

### SEQUENTIAL LOGIC ###
# Welcome the user.
echo -e "${BOLD_TEXT}\
################################################################################
#                                                                              #
#                            WinApps Install Wizard                            #
#                                                                              #
################################################################################
${CLEAR_TEXT}"

# Check dependencies for the script.
waCheckScriptDependencies

# Source the contents of 'inquirer.sh'.
# shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
source "$INQUIRER_PATH"

# Set the working directory.
waSetWorkingDirectory

# Sanitise and parse the user input.
waCheckInput "$@"

# Configure paths and permissions.
waConfigurePathsAndPermissions

# Install or uninstall WinApps.
if [ "$OPT_UNINSTALL" -eq 1 ]; then
    waUninstall
else
    waInstall
fi

exit 0
