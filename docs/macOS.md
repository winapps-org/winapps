# WinApps on macOS

Run Windows applications on macOS via RDP RemoteApp, using the system RDP client (Microsoft "Windows App").

## Prerequisites

1. **Microsoft "Windows App"** (free) from the [Mac App Store](https://apps.apple.com/app/windows-app/id1295203466)
2. **`dialog`** — required for the interactive installer (`brew install dialog`)
3. A **Windows machine with RDP enabled** (VM, remote server, or local Parallels/UTM)
4. **RDP RemoteApp configured** on the Windows machine (merge `install/RDPApps.reg`)

## Installation

### Via Homebrew (recommended)

```bash
brew tap dingyifei/winapps
brew install winapps
```

### Manual

```bash
git clone https://github.com/dingyifei/winapps-macos.git
cd winapps-macos
```

## Configuration

Create the config file:

```bash
mkdir -p ~/.config/winapps
cat > ~/.config/winapps/winapps.conf << 'EOF'
RDP_IP=192.168.1.100
RDP_USER=MyWindowsUser
RDP_PASS=MyPassword
RDP_DOMAIN=WORKGROUP
EOF
chmod 600 ~/.config/winapps/winapps.conf
```

Set `RDP_IP` to your Windows machine's IP address. Unlike Linux, macOS does not support KVM auto-detection, so `RDP_IP` is **required**.

### Optional: `TSCLIENT_HOME`

WinApps auto-detects your macOS volume name (e.g., `Macintosh HD`) to compute the correct `\\tsclient\...` path for file passthrough. If auto-detection fails or you use a non-standard volume name, you can override it:

```bash
TSCLIENT_HOME='\\tsclient\Macintosh HD\Users\myuser'
```

## Windows Setup

1. **Enable Remote Desktop** on the Windows machine
2. **Import the RemoteApp registry settings**:
   - Copy `install/RDPApps.reg` to the Windows machine
   - Double-click to merge it into the registry
3. Optionally run `install/ExtractPrograms.ps1` to verify app detection

## Install App Shortcuts (Scan-and-Generate)

Run the installer to scan for installed Windows apps and create CLI wrappers:

```bash
# User install (~/.local/bin)
bash setup.sh --user

# System install (/usr/local/bin)
bash setup.sh --system
```

The installer will:
1. Connect to your Windows machine via RDP
2. Scan for installed applications
3. Create CLI wrapper scripts (e.g., `~/.local/bin/word`, `~/.local/bin/excel`)

On macOS, the installer skips `.desktop` file creation (Linux-only) and creates CLI wrappers only.

## Usage

```bash
# Full Windows desktop
winapps windows

# Launch a pre-configured app
winapps word
winapps excel

# Launch an app with a file
winapps word ~/Documents/report.docx

# Launch any Windows executable
winapps manual "C:\Windows\System32\notepad.exe"
```

## How It Works

On macOS, WinApps generates `.rdp` files dynamically and opens them with the system `open` command, which delegates to Microsoft "Windows App". This avoids the FreeRDP/XQuartz dependency chain.

- `winapps word` generates a temporary `.rdp` file with RemoteApp settings and opens it
- `winapps windows` generates a full desktop `.rdp` file
- Files passed as arguments are mapped through `\\tsclient\<Volume Name>\Users\...` (drive redirection)

### Path Mapping

On Linux, FreeRDP's `+home-drive` flag maps `$HOME` to `\\tsclient\home`.

On macOS, Microsoft "Windows App" with `drivestoredirect:s:*` maps volumes by name:
`\\tsclient\Macintosh HD\Users\username\...`

WinApps auto-detects the volume name via `diskutil info /` and computes the correct tsclient base path.

## Credential Handling

Passwords are not stored in `.rdp` files for security. The RDP client will prompt for credentials on first connection and can save them in the macOS Keychain.

## Troubleshooting

- **"Windows App" not opening**: Ensure it's installed from the Mac App Store
- **Connection refused**: Verify `RDP_IP` is correct and RDP is enabled on Windows
- **RemoteApp not working**: Ensure `install/RDPApps.reg` was merged on the Windows machine
- **Files not accessible**: Check that drive redirection is enabled (it is by default in generated `.rdp` files)
- **Wrong volume name detected**: Override with `TSCLIENT_HOME` in your config file
- **`nc` timeout errors**: macOS uses `-w` flag for timeout instead of the `timeout` wrapper; this is handled automatically
