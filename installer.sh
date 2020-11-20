#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

. "${DIR}/install/inquirer.sh"

INSTALLED_EXES=()

function waUsage() {
	echo 'Usage:
  ./installer.sh --user    # Install everything in ${HOME}
  ./installer.sh --system  # Install everything in /usr'
	exit
}

function waNoSudo() {
	echo 'You are attempting to switch from a --system install to a --user install.
Please run "./installer.sh --system --uninstall" first.'
	exit
}

function waInstall() {
	${SUDO} mkdir -p "${SYS_PATH}/apps"
	. "${DIR}/bin/winapps" install
}

function waFindInstalled() {
	echo -n "  Checking for installed apps in RDP machine (this may take a while)..."
	rm -f ${HOME}/.local/share/winapps/installed.bat
	rm -f ${HOME}/.local/share/winapps/installed.tmp
	rm -f ${HOME}/.local/share/winapps/installed
	cp "${DIR}/install/ExtractPrograms.ps1" ${HOME}/.local/share/winapps/ExtractPrograms.ps1
	for F in $(ls "${DIR}/apps"); do
		. "${DIR}/apps/${F}/info"
		echo "IF EXIST \"${WIN_EXECUTABLE}\" ECHO ${F} >> \\\\tsclient\\home\\.local\\share\\winapps\\installed.tmp" >> ${HOME}/.local/share/winapps/installed.bat
	done;
	echo "powershell.exe -ExecutionPolicy Bypass -File \\\\tsclient\\home\\.local\\share\\winapps\\ExtractPrograms.ps1 > \\\\tsclient\home\\.local\\share\\winapps\\detected" >> ${HOME}/.local/share/winapps/installed.bat
	echo "RENAME \\\\tsclient\\home\\.local\\share\\winapps\\installed.tmp installed" >> ${HOME}/.local/share/winapps/installed.bat
	xfreerdp /d:"${RDP_DOMAIN}" /u:"${RDP_USER}" /p:"${RDP_PASS}" /v:${RDP_IP} +auto-reconnect +home-drive -wallpaper /span /wm-class:"RDPInstaller" /app:"C:\Windows\System32\cmd.exe" /app-icon:"${DIR}/../icons/windows.svg" /app-cmd:"/C \\\\tsclient\\home\\.local\\share\\winapps\\installed.bat" 1> /dev/null 2>&1 &
	COUNT=0
	while [ ! -f "${HOME}/.local/share/winapps/installed" ]; do
		sleep 5
		COUNT=$((COUNT + 1))
		if (( COUNT == 15 )); then
			echo " Finished."
			echo ""
			echo "The RDP connection failed to connect or run. Please confirm FreeRDP can connect with:"
			echo "  bin/winapps check"
			echo ""
			echo "If it cannot connect, this is most likely due to:"
			echo "  - You need to accept the security cert the first time you connect (with 'check')"
			echo "  - Not enabling RDP in the Windows VM"
			echo "  - Not being able to connect to the IP of the VM"
			echo "  - Incorrect user credentials in winapps.conf"
			echo "  - Not merging install/RDPApps.reg into the VM"
			exit
		fi
	done
	echo " Finished."
}

function waConfigureApp() {
		. "${SYS_PATH}/apps/${1}/info"
		echo -n "  Configuring ${NAME}..."
		${SUDO} rm -f "${APP_PATH}/${1}.desktop"
		echo "[Desktop Entry]
Name=${NAME}
Exec=${BIN_PATH}/winapps ${1} %F
Terminal=false
Type=Application
Icon=${SYS_PATH}/apps/${1}/icon.${2}
StartupWMClass=${FULL_NAME}
Comment=${FULL_NAME}
Categories=${CATEGORIES}
MimeType=${MIME_TYPES}
" |${SUDO} tee "${APP_PATH}/${1}.desktop" > /dev/null
	${SUDO} rm -f "${BIN_PATH}/${1}"
	echo "#!/usr/bin/env bash
${BIN_PATH}/winapps ${1} $@
" |${SUDO} tee "${BIN_PATH}/${1}" > /dev/null
		${SUDO} chmod a+x "${BIN_PATH}/${1}"
		echo " Finished."
}

function waConfigureApps() {
	APPS=()
	for F in $(cat "${HOME}/.local/share/winapps/installed" |sed 's/\r/\n/g'); do
		. "${DIR}/apps/${F}/info"
		APPS+=("${FULL_NAME} (${F})")
		INSTALLED_EXES+=("$(echo "${WIN_EXECUTABLE##*\\}" |tr '[:upper:]' '[:lower:]')")
	done
	IFS=$'\n' APPS=($(sort <<<"${APPS[*]}"))
	unset IFS
	OPTIONS=("Set up all detected pre-configured applications" "Select which pre-configured applications to set up" "Do not set up any pre-configured applications")
	menuFromArr APP_INSTALL "How would you like to handle WinApps pre-configured applications?" "${OPTIONS[@]}"
	if [ "${APP_INSTALL}" = "Select which pre-configured applications to set up" ]; then
		checkbox_input "Which pre-configured apps would you like to set up?" APPS SELECTED_APPS
		echo "" > "${HOME}/.local/share/winapps/installed"
		for F in "${SELECTED_APPS[@]}"; do
			APP="${F##*(}"
			APP="${APP%%)}"
			echo "${APP}" >> "${HOME}/.local/share/winapps/installed"
		done
	fi	
	${SUDO} cp "${DIR}/bin/winapps" "${BIN_PATH}/winapps"
	COUNT=0
	if [ "${APP_INSTALL}" != "Do not set up any pre-configured applications" ]; then
		for F in $(cat "${HOME}/.local/share/winapps/installed" |sed 's/\r/\n/g'); do
			COUNT=$((COUNT + 1))
			${SUDO} cp -r "apps/${F}" "${SYS_PATH}/apps"
			waConfigureApp "${F}" svg
		done
	fi
	rm -f "${HOME}/.local/share/winapps/installed"
	rm -f "${HOME}/.local/share/winapps/installed.bat"
	if (( $COUNT == 0 )); then
		echo "  No configured applications."
	fi
}

function waConfigureDetectedApps() {
	if [ -f "${HOME}/.local/share/winapps/detected" ]; then
		sed -i 's/\r//g' "${HOME}/.local/share/winapps/detected"
		. "${HOME}/.local/share/winapps/detected"
		APPS=()
		for I in "${!NAMES[@]}"; do
			EXE=${EXES[$I]##*\\}
			EXE_LOWER=$(echo "${EXE}" |tr '[:upper:]' '[:lower:]')
			if ( dlm=$'\x1F' ; IFS="$dlm" ; [[ "$dlm${INSTALLED_EXES[*]}$dlm" != *"$dlm${EXE_LOWER}$dlm"* ]] ) ; then
				APPS+=("${NAMES[$I]} (${EXE})")
			fi
		done
		IFS=$'\n' APPS=($(sort <<<"${APPS[*]}"))
		unset IFS
		OPTIONS=("Set up all detected applications" "Select which applications to set up" "Do not set up any applications")
		menuFromArr APP_INSTALL "How would you like to handle other detected applications?" "${OPTIONS[@]}"
		if [ "${APP_INSTALL}" = "Select which applications to set up" ]; then
			checkbox_input "Which other apps would you like to set up?" APPS SELECTED_APPS
			echo "" > "${HOME}/.local/share/winapps/installed"
			for F in "${SELECTED_APPS[@]}"; do
				EXE="${F##*(}"
				EXE="${EXE%%)}"
				APP="${F% (*}"
				echo "${EXE}|${APP}" >> "${HOME}/.local/share/winapps/installed"
			done
		elif [ "${APP_INSTALL}" = "Set up all detected applications" ]; then
			for I in "${!EXES[@]}"; do
				EXE=${EXES[$I]##*\\}
				echo "${EXE}|${NAMES[$I]}" >> "${HOME}/.local/share/winapps/installed"
			done
		fi
		COUNT=0
		if [ -f "${HOME}/.local/share/winapps/installed" ]; then
			while read LINE; do
				EXE="${LINE%|*}"
				NAME="${LINE#*|}"
				for I in "${!NAMES[@]}"; do
					if [ "${NAME}" = "${NAMES[$I]}" ] && [[ "${EXES[$I]}" == *"\\${EXE}" ]]; then
						EXE=$(echo "${EXE}" |tr '[:upper:]' '[:lower:]')
						${SUDO} mkdir -p "${SYS_PATH}/apps/${EXE}"
						echo "# GNOME shortcut name
NAME=\"${NAME}\"

# Used for descriptions and window class
FULL_NAME=\"${NAME}\"

# The executable inside windows
WIN_EXECUTABLE=\"${EXES[$I]}\"

# GNOME categories
CATEGORIES=\"WinApps\"

# GNOME mimetypes
MIME_TYPES=\"\"
" > "${SYS_PATH}/apps/${EXE}/info"
						echo "${ICONS[$I]}" | base64 -d > "${SYS_PATH}/apps/${EXE}/icon.ico"
						waConfigureApp "${EXE}" ico
						COUNT=$((COUNT + 1))
					fi
				done
			done < "${HOME}/.local/share/winapps/installed"
			rm -f "${HOME}/.local/share/winapps/installed"
		fi
		rm -f "${HOME}/.local/share/winapps/installed.bat"
		if (( $COUNT == 0 )); then
			echo "  No configured applications."
		fi
	fi
}


function waConfigureWindows() {
	echo -n "  Configuring Windows..."
	${SUDO} rm -f "${APP_PATH}/windows.desktop"
	${SUDO} mkdir -p "${SYS_PATH}/icons"
	${SUDO} cp "${DIR}/icons/windows.svg" "${SYS_PATH}/icons/windows.svg"
	echo "[Desktop Entry]
Name=Windows
Exec=${BIN_PATH}/winapps windows %F
Terminal=false
Type=Application
Icon=${SYS_PATH}/icons/windows.svg
StartupWMClass=Micorosoft Windows
Comment=Micorosoft Windows
Categories=Windows
" |${SUDO} tee "${APP_PATH}/windows.desktop" > /dev/null
	${SUDO} rm -f "${BIN_PATH}/windows"
	echo "#!/usr/bin/env bash
${BIN_PATH}/winapps windows
" |${SUDO} tee "/${BIN_PATH}/windows" > /dev/null
	${SUDO} chmod a+x "${BIN_PATH}/windows"
	echo " Finished."
}

function waUninstallUser() {
	rm -f "${HOME}/.local/bin/winapps"
	rm -rf "${HOME}/.local/share/winapps"
	for F in $(grep -l -d skip "bin/winapps" "${HOME}/.local/share/applications/"*); do
		echo -n "  Removing ${F}..."
		${SUDO} rm ${F}
		echo " Finished."
	done
	for F in $(grep -l -d skip "bin/winapps" "${HOME}/.local/bin/"*); do
		echo -n "  Removing ${F}..."
		${SUDO} rm ${F}
		echo " Finished."
	done
}

function waUninstallSystem() {
	${SUDO} rm -f "/usr/local/bin/winapps"
	${SUDO} rm -rf "/usr/local/share/winapps"
	for F in $(grep -l -d skip "bin/winapps" "/usr/share/applications/"*); do
		if [ -z "${SUDO}" ]; then
			waNoSudo
		fi
		echo -n "  Removing ${F}..."
		${SUDO} rm ${F}
		echo " Finished."
	done
	for F in $(grep -l -d skip "bin/winapps" "/usr/local/bin/"*); do
		if [ -z "${SUDO}" ]; then
			waNoSudo
		fi
		echo -n "  Removing ${F}..."
		${SUDO} rm ${F}
		echo " Finished."
	done
}

if [ -z "${1}" ]; then
	OPTIONS=(User System)
	menuFromArr INSTALL_TYPE "Would you like to install for the current user or the whole system?" "${OPTIONS[@]}"
elif [ "${1}" = '--user' ]; then
	INSTALL_TYPE='User'
elif [ "${1}" = '--system' ]; then
	INSTALL_TYPE='System'
else
	waUsage
fi

if [ "${INSTALL_TYPE}" = 'User' ]; then
	SUDO=""
	BIN_PATH="${HOME}/.local/bin"
	APP_PATH="${HOME}/.local/share/applications"
	SYS_PATH="${HOME}/.local/share/winapps"
	if [ -n "${2}" ]; then
		if [ "${2}" = '--uninstall' ]; then
			# Uninstall
			echo "Uninstalling..."
			waUninstallUser
			exit
		else
			usage
		fi
	fi
elif [ "${INSTALL_TYPE}" = 'System' ]; then
	SUDO="sudo"
	sudo ls > /dev/null
	BIN_PATH="/usr/local/bin"
	APP_PATH="/usr/share/applications"
	SYS_PATH="/usr/local/share/winapps"
	if [ -n "${2}" ]; then
		if [ "${2}" = '--uninstall' ]; then
			# Uninstall
			echo "Uninstalling..."
			waUninstallSystem
			exit
		else
			usage
		fi
	fi
fi

echo "Removing any old configurations..."
waUninstallUser
waUninstallSystem

echo "Installing..."

# Inititialize
waInstall

# Check for installed apps
waFindInstalled

# Install windows
waConfigureWindows

# Configure apps
waConfigureApps
waConfigureDetectedApps

echo "Installation complete."