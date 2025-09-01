# Script to monitor if there is a sleep_marker created by WinApps (indicating the Linux host was suspended) in order to trigger a time sync as the time in the Windows VM will otherwise drift while Linux is suspended.

# Define the path to monitor. Make sure this matches the location for the sleep_marker in the Winapps script (need to match the APPDATA path).
$filePath = "\\tsclient\home\.local\share\winapps\sleep_marker"
$networkPath = "\\tsclient\home"

# Function to check and handle file
function Monitor-File {
    while ($true) {
        # Check if network location is available
        try {
            $null = Test-Path -Path $networkPath -ErrorAction Stop
            # Check if file exists
            if (Test-Path -Path $filePath) {
                # Run time resync silently
                w32tm /resync /quiet

                # Remove the file
                Remove-Item -Path $filePath -Force
            }
        }
        catch {
            # Network location not available, continue monitoring silently
        }

        # Wait 5 minutes before next check
        Start-Sleep -Seconds 3000
    }
}

# Start monitoring silently
Monitor-File
