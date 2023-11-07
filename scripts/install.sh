#!/bin/sh

# This install script is intended to download and install the latest available
# release of the winapps rewrite..
#
# It attempts to identify the current platform and an error will be thrown if
# the platform is not supported.
# It is based on the install script from dep (https://raw.githubusercontent.com/golang/dep/master/install.sh)
#
# Environment variables:
# - INSTALL_DIRECTORY (optional): defaults to ~/.local/bin
# - WINAPPS_RELEASE_TAG (optional): defaults to fetching the latest release
# - WINAPPS_USE_MUSL (optional): use musl instead of glibc
# - WINAPPS_ARCH (optional): use a specific value for ARCH (mostly for testing)
#
# You can install using this script:
# $ curl https://raw.githubusercontent.com/winapps-org-winapps/rewrite/scripts/install.sh | sh

set -e

RELEASES_URL="https://github.com/winapps-org/winapps/releases"

downloadJSON() {
    url="$2"

    echo "Fetching $url.."
    if test -x "$(command -v curl)"; then
        response=$(curl -s -L -w 'HTTPSTATUS:%{http_code}' -H 'Accept: application/json' "$url")
        body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
        code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    elif test -x "$(command -v wget)"; then
        temp=$(mktemp)
        body=$(wget -q --header='Accept: application/json' -O - --server-response "$url" 2> "$temp")
        code=$(awk '/^  HTTP/{print $2}' < "$temp" | tail -1)
        rm "$temp"
    else
        echo "Neither curl nor wget was available to perform http requests."
        exit 1
    fi
    if [ "$code" != 200 ]; then
        echo "Request failed with code $code"
        exit 1
    fi

    eval "$1='$body'"
}

downloadFile() {
    url="$1"
    destination="$2"

    echo "Fetching $url.."
    if test -x "$(command -v curl)"; then
        code=$(curl -s -w '%{http_code}' -L "$url" -o "$destination")
    elif test -x "$(command -v wget)"; then
        code=$(wget -q -O "$destination" --server-response "$url" 2>&1 | awk '/^  HTTP/{print $2}' | tail -1)
    else
        echo "Neither curl nor wget was available to perform http requests."
        exit 1
    fi

    if [ "$code" != 200 ]; then
        echo "Request failed with code $code"
        exit 1
    fi
}

initArch() {
    ARCH=$(uname -m)
    if [ -n "$WINAPPS_ARCH" ]; then
        echo "Using WINAPPS_ARCH"
        ARCH="$WINAPPS_ARCH"
    fi
    case $ARCH in
        amd64) ARCH="amd64";;
        x86_64) ARCH="amd64";;
        i386) ARCH="i686";;
        i686) ARCH="i686";;
        *) echo "Architecture ${ARCH} is not supported by winapps"; exit 1;;
    esac
    echo "ARCH = $ARCH"
}

initOS() {
    OS=$(uname | tr '[:upper:]' '[:lower:]')
    case "$OS" in
        linux) OS='linux';;
        *) echo "OS ${OS} is not supported by winapps"; exit 1;;
    esac
    echo "OS = $OS"
}

# identify platform based on uname output
initArch
initOS

# determine install directory if required
if [ -z "$INSTALL_DIRECTORY" ]; then
    if [ -d "$HOME/.local/bin" ]; then
        INSTALL_DIRECTORY="$HOME/.local/bin"
    else
        echo "Installation directory not specified and ~/.local/bin does not exist"
        exit 1
    fi
fi
echo "Will install into $INSTALL_DIRECTORY"
echo "Make sure it is on your PATH"

if [ -n "$WINAPPS_USE_MUSL" ]; then
    BINARY="winapps-${OS}-${ARCH}-musl"
else
    BINARY="winapps-${OS}-${ARCH}"
fi

# if WINAPPS_RELEASE_TAG was not provided, assume latest
if [ -z "$WINAPPS_RELEASE_TAG" ]; then
    downloadJSON LATEST_RELEASE "$RELEASES_URL/latest"
    WINAPPS_RELEASE_TAG=$(echo "${LATEST_RELEASE}" | tr -s '\n' ' ' | sed 's/.*"tag_name":"//' | sed 's/".*//' )
fi
echo "Release Tag = $WINAPPS_RELEASE_TAG"

# fetch the real release data to make sure it exists before we attempt a download
downloadJSON RELEASE_DATA "$RELEASES_URL/tag/$WINAPPS_RELEASE_TAG"

BINARY_URL="$RELEASES_URL/download/$WINAPPS_RELEASE_TAG/$BINARY"
DOWNLOAD_FILE=$(mktemp)

downloadFile "$BINARY_URL" "$DOWNLOAD_FILE"

echo "Setting executable permissions."
chmod +x "$DOWNLOAD_FILE"

INSTALL_NAME="winapps"

echo "Moving executable to $INSTALL_DIRECTORY/$INSTALL_NAME"
mv "$DOWNLOAD_FILE" "$INSTALL_DIRECTORY/$INSTALL_NAME"

if test -x "$(command -v python3)"; then
    curl https://raw.githubusercontent.com/winapps-org/winapps/rewrite/scripts/install_quickemu.py | python3
else
    echo "python3 is not installed. Please install it in order to install quickemu."
    echo "Once you have installed python3, run the following command to install quickemu:"
    echo "curl https://raw.githubusercontent.com/winapps-org/winapps/rewrite/scripts/install_quickemu.py | python3"
    echo "You may ignore this if quickemu is already installed."
    exit 1
fi
