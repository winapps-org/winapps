function Import-Registry {
    # Import default registry settings
    reg import "$PSScriptRoot\RDPApps.reg"

    # The container.reg should only exist if we are inside a container,
    # so check before loading
    if (Test-Path "$PSScriptRoot\Container.reg") {
        reg import "$PSScriptRoot\Container.reg"
    }
}

function Setup-NetProfileCleanup {
    # Copy the NetProfileCleanup.ps1 script to C:\Windows for safe keeping
    Copy-Item "$PSScriptRoot\NetProfileCleanup.ps1" -Destination "$env:windir" -Force

    $taskname = "NetworkProfileCleanup"
    $command = "powershell.exe -ExecutionPolicy Bypass -File $env:windir\NetProfileCleanup.ps1"

    # Check if the scheduled task exists and delete it if it does
    if (schtasks /query /tn $taskname -ErrorAction SilentlyContinue) {
        Write-Output "Task $taskname already exists, deleting it first..."
        schtasks /delete /tn $taskname /f
    }

    # Create the scheduled task and check if it was successful
    if (schtasks /create /tn $taskname /tr $command /sc onstart /ru "SYSTEM" /rl HIGHEST /f) {
        Write-Output "Scheduled task $taskname created successfully."
    } else {
        Write-Output "Failed to create scheduled task."
    }
}

Import-Registry
Setup-NetProfileCleanup
