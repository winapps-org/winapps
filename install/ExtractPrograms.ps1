### FUNCTIONS ###
# Name: 'GetApplicationIcon'
# Role: Extract the icon from a given executable file as a base-64 string.
# Args:
#    - 'exePath': Provides the path to the executable file.
Function GetApplicationIcon {
    param (
        [Parameter(Mandatory = $true)]
        [string]$exePath
    )

    try {
        # Load the 'System.Drawing' assembly to access 'ExtractAssociatedIcon'.
        Add-Type -AssemblyName System.Drawing

        # Extract the icon from the executable.
        $exeIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)

        # Create a bitmap from the icon.
        $exeIconBitmap = New-Object System.Drawing.Bitmap $exeIcon.Width, $exeIcon.Height
        $graphics = [System.Drawing.Graphics]::FromImage($exeIconBitmap)
        $graphics.DrawIcon($exeIcon, 0, 0)

        # Save the bitmap to a 'MemoryStream' as a '.PNG' to preserve the icon colour depth.
        $memoryStream = New-Object System.IO.MemoryStream
        $exeIconBitmap.Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)

        # Convert the PNG 'MemoryStream' to a base-64 string.
        $bytes = $memoryStream.ToArray()
        $base64String = [Convert]::ToBase64String($bytes)

        # Clean up.
        $memoryStream.Flush()
        $memoryStream.Dispose()
        $graphics.Dispose()
        $exeIconBitmap.Dispose()
        $exeIcon.Dispose()
    } catch {
        # Use a generic 32x32 PNG.
        $base64String = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAAAXNSR0IB2cksfwAAAAlwSFlzAAALEwAACxMBAJqcGAAAASZQTFRFAAAA+vr65ubm4uLkhYmLvL7A7u7w+/r729vb4eHjFYPbFoTa5eXnGIbcG4jc+fn7Gofc7+/x7OzuF4Xb+fn54uLiC37Z5OTmEIHaIIjcEYHbDoDZFIPcJ43fHYjd9fX28PDy3d3fI4rd3d3dHojc19fXttTsJIve2dnZDX/YCn3Y09PTjL/p5+fnh7zo2traJYzfIYjdE4Pb6urrW6Tf9PT1Ioneir7otNPsCX3Zhbvn+Pj5YKfhJYfWMo7a39/gKIzeKo7eMI3ZNJDcXqbg4eHhuNTsB3zYIoncBXvZLIrXIYjbLJDgt7m6ubu+YqjiKYvYvr6+tba3rs/sz8/P1+byJonXv7/DiImLxsbGjo6Ra6reurq6io6QkJKVw8PD0tLSycnJq1DGywAAAGJ0Uk5TAP////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+BVJDaAAABY0lEQVR4nM2RaVOCUBSGr1CBgFZimppgoGnKopZSaYGmRpravq///0904IqOM9j00WeGT+9ztgtCS8Dzyh98fL6i2+HqQoaj0RPSzQNgzZc4F4wgvUuoqkr1er094MjlIeBCwRdFua9CqURQ51cty7Lykj0YCIIibnlEkS4TgCuky3nbTmSFsCKSHuso96N/Ox1aacjrlYQQ3gjNCYV7UlUJ6szCeRZyXmlkNjEZEPSuLIMAuYTreVYROQ8Y8SLTNAhlCdfzLMsaIhfHgEAT7pLtvFTH9QxTNWrmLsaEDu8558y2ZOP5LLNTNUQyiCFnHaRZnjTmzryhnR36FSdnIU9up7RGxAOuKJjOFX2vHvKU5jPiepbvxzR3BIffwROc++AAJy9qjQxQwz9rIjyGeN6tj8VACEyZCqfQn3H7F48vTvwEdlIP+aWvMNkPcl8h8DYeN5vNTqdzCNz5CIv4h7AE/AKcwUFbShJywQAAAABJRU5ErkJggg=="
    }

    # Return the base-64 string.
    return $base64String
}

# Name: 'PrintArrayData'
# Role: Print application names, executable paths and base-64 encoded icons in a format suitable for importing into bash arrays.
# Args:
#    - 'Names': An array of application names.
#    - 'Paths': An array of executable paths.
#    - 'Source': The source of the applications (e.g. Windows Registry, Package manangers, Universal Windows Platform (UWP), etc.)
function PrintArrayData {
    param (
        [string[]]$Names,
        [string[]]$Paths,
        [string]$Source
    )

    # Combine the arrays into an array of objects
    $NamesandPaths = @()
    for ($i = 0; $i -lt $Names.Length; $i++) {
        $NamesandPaths += [PSCustomObject]@{
            Name = $Names[$i]
            Path = $Paths[$i]
        }
    }

    # Sort the combined array based on the application names.
    $NamesandPaths = $NamesandPaths | Sort-Object {$_.Name}

    # Loop through the extracted executable file paths.
    foreach ($Application in $NamesandPaths) {

        # Remove undesirable suffix for chocolatey shims.
        if ($Source -eq "choco") {
            if ($Application.Name.EndsWith(" - Chocolatey Shim")) {
                $Application.Name = $Application.Name.Substring(0, $Application.Name.Length - " - Chocolatey Shim".Length)
            }
        }

        # Add the appropriate tag to the application name.
        if ($Source -ne "winreg") {
            $Application.Name = $Application.Name + " [" + $Source.ToUpper() + "]"
        }

        # Store the application icon as a base-64 string.
        $Icon = GetApplicationIcon -exePath $Application.Path

        # Output the results as bash commands that append the results to several bash arrays.
        Write-Output ('NAMES+=("' + $Application.Name + '")')
        Write-Output ('EXES+=("' + $Application.Path + '")')
        Write-Output ('ICONS+=("' + $Icon + '")')
    }
}

# Name: 'GetApplicationName'
# Role: Determine the application name for a given executable file.
# Args:
#    - 'exePath': The path to a given executable file.
function GetApplicationName {
    param (
        [string]$exePath
    )

    try {
        $productName = (Get-Item $exePath).VersionInfo.FileDescription.Trim() -replace '\s+', ' '
    } catch {
        $productName = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
    }

    return $productName
}

# Name: 'GetUWPApplicationName'
# Role: Determine the application name for a given UWP application.
# Args:
#    - 'exePath': The path to a given executable file.
function GetUWPApplicationName {
    param (
        [string]$exePath
    )

    # Query the application executable for the application name.
    if (Test-Path $exePath) {
        $productName = GetApplicationName -exePath $exePath
    }

    # Use the 'DisplayName' (if available) if the previous method failed.
    if (-not $productName -and $app.DisplayName) {
        $productName = $app.DisplayName
    }

    # Use the 'Name' (if available) as a final fallback.
    if (-not $productName -and $app.Name) {
        $productName = $app.Name
    }

    return $productName
}

# Name: 'GetUWPExecutablePath'
# Role: Obtain the UWP application executable path from 'AppxManifest.xml'.
# Args:
#    - 'instLoc': UWP application folder path (C:\Program Files\WindowsApps\*).
function GetUWPExecutablePath {
    param (
        [string]$instLoc
    )

    # Determine the path to 'AppxManifest.xml' for the selected application.
    $manifestPath = Join-Path -Path $instLoc -ChildPath "AppxManifest.xml"

    if (Test-Path $manifestPath) {
        # Parse the XML file.
        [xml]$manifest = Get-Content $manifestPath
        $applications = $manifest.Package.Applications.Application

        # Return the path to the first executable specified within the XML.
        foreach ($application in $applications) {
            $executable = $application.Executable
            if ($executable) {
                return Join-Path -Path $instLoc -ChildPath $executable
            }
        }
    }

    # Return 'null' if nothing was found.
    return $null
}

# Name: 'AppSearchWinReg'
# Role: Search the Windows Registry for installed applications.
function AppSearchWinReg {
    # Initialise empty arrays.
    $exeNames = @()
    $exePaths = @()
    $validPaths = @()

    # Query windows registry for unique installed executable files.
    $exePaths = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*" |
        ForEach-Object { $_."(default)" } |  # Extract the value of the (default) property
        Where-Object { $_ -ne $null } |  # Filter out null values
        Sort-Object -Unique  # Ensure uniqueness

    # Remove leading and trailing double quotes from all paths.
    $exePaths = $exePaths -replace '^"*|"*$'

    # Get corresponding application names for unique installed executable files.
    foreach ($exePath in $exePaths) {
        if (Test-Path -Path $exePath) {
            $validPaths += $exePath
            $exeNames += GetApplicationName -exePath $exePath
        }
    }

    # Process extracted executable file paths.
    PrintArrayData -Names $exeNames -Paths $validPaths -Source "winreg"
}

# Name: 'AppSearchUWP'
# Role: Search for 'non-system' UWP applications.
function AppSearchUWP {
    # Initialise empty arrays.
    $exeNames = @()
    $exePaths = @()

    # Obtain all 'non-system' UWP applications using 'Get-AppxPackage'.
    $uwpApps = Get-AppxPackage | Where-Object {
        $_.IsFramework -eq $false -and
        $_.IsResourcePackage -eq $false -and
        $_.SignatureKind -ne 'System'
    }

    # Create an array to store UWP application details.
    $uwpAppDetails = @()

    # Loop through each UWP application.
    foreach ($app in $uwpApps) {
        # Initialise the variable responsible for storing the UWP application name.
        $productName = $null

        # Obtain the path to the UWP application executable.
        $exePath = GetUWPExecutablePath -instLoc $app.InstallLocation

        # Proceed only if an executable path was identified.
        if ($exePath) {
            $productName = GetUWPApplicationName -exePath $exePath

            # Ignore UWP applications with no name, or those named 'Microsoft® Windows® Operating System'.
            if ($productName -ne "Microsoft® Windows® Operating System" -and [string]::IsNullOrEmpty($productName) -eq $false) {
                # Store the UWP application name and executable path.
                $exeNames += $productName
                $exePaths += $exePath
            }
        }
    }

    # Process extracted executable file paths.
    PrintArrayData -Names $exeNames -Paths $exePaths -Source "uwp"
}

# Name: 'AppSearchWinReg'
# Role: Search for chocolatey shims.
function AppSearchChocolatey {
    # Initialise empty arrays.
    $exeNames = @()
    $exePaths = @()

    # Specify the 'chocolatey' shims directory.
    $chocoDir = "C:\ProgramData\chocolatey\bin"

    # Check if the 'chocolatey' shims directory exists.
    if (Test-Path -Path $chocoDir -PathType Container) {
        # Get all shim '.exe' files.
        $shimExeFiles = Get-ChildItem -Path $chocoDir -Filter *.exe

        # Loop through each '.shim' file to extract the executable path.
        foreach ($shimExeFile in $shimExeFiles) {
            # Resolve the shim to the actual executable path.
            $exePath = (Get-Command $shimExeFile).Source

            # Proceed only if an executable path was identified.
            if ($exePath) {
                $exeNames += GetApplicationName -exePath $exePath
                $exePaths += $exePath
            }
        }

        # Process extracted executable file paths.
        PrintArrayData -Names $exeNames -Paths $exePaths -Source "choco"
    }
}

# Name: 'AppSearchWinReg'
# Role: Search for scoop shims.
function AppSearchScoop {
    # Initialise empty arrays.
    $exeNames = @()
    $exePaths = @()

    # Specify the 'scoop' shims directory.
    $scoopDir = "$HOME\scoop\shims"

    # Check if the 'scoop' shims directory exists.
    if (Test-Path -Path $scoopDir -PathType Container) {
        # Get all '.shim' files.
        $shimFiles = Get-ChildItem -Path $scoopDir -Filter *.shim

        # Loop through each '.shim' file to extract the executable path.
        foreach ($shimFile in $shimFiles) {
            # Read the content of the '.shim' file.
            $shimFileContent = Get-Content -Path $shimFile.FullName

            # Extract the path using regex, exiting the loop after the first match is found.
            $exePath = ""

            foreach ($line in $shimFileContent) {
                # '^\s*path\s*=\s*"([^"]+)"'
                # ^       --> Asserts the start of the line.
                # \s*     --> Matches any whitespace characters (zero or more times).
                # path    --> Matches the literal string "path".
                # \s*=\s* --> Matches an equal sign = surrounded by optional whitespace characters.
                # "       --> Matches an initial double quote.
                # ([^"]+) --> Captures one or more characters that are not ", representing the path inside the double quotes.
                # "       --> Matches a final double quote.
                if ($line -match '^\s*path\s*=\s*"([^"]+)"') {
                    $exePath = $matches[1]
                    break
                }
            }

            if ($exePath -ne "") {
                $exeNames += GetApplicationName -exePath $exePath
                $exePaths += $exePath
            }
        }

        # Process extracted executable file paths.
        PrintArrayData -Names $exeNames -Paths $exePaths -Source "scoop"
    }
}

### SEQUENTIAL LOGIC ###
# Print bash commands to define three new arrays.
Write-Output 'NAMES=()'
Write-Output 'EXES=()'
Write-Output 'ICONS=()'

# Search for installed applications.
AppSearchWinReg     # Windows Registry
if (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue){
    AppSearchUWP        # Universal Windows Platform
}
AppSearchChocolatey # Chocolatey Package Manager
AppSearchScoop      # Scoop Package Manager
