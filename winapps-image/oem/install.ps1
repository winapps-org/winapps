$ErrorActionPreference = "Stop"

function Install-OpenSSH
{
    # Based on https://github.com/containerd/containerd/blob/main/script/setup/enable_ssh_windows.ps1

    Get-WindowsCapability -Online -Name OpenSSH* | Add-WindowsCapability -Online
    Set-Service -Name sshd -StartupType Automatic
    Start-Service sshd

    # Set PowerShell as default shell
    New-ItemProperty -Force -Path "HKLM:\SOFTWARE\OpenSSH" -PropertyType String `
                 -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
}

function Load-Registry
{
    reg import "$PSScriptRoot\RDPApps.reg"
    reg import "$PSScriptRoot\Container.reg"
}

function Install-NetworkProfileCleanup
{
    Copy-Item -Path "$PSScriptRoot\NetProfileCleanup.ps1" -Destination "$env:windir" -Force

    $taskName = "NetworkProfileCleanup"
    $command = "powershell.exe -ExecutionPolicy Bypass -File `"$env:windir\NetProfileCleanup.ps1`""

    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)
    {
        Write-Host "Task `"$taskName`" already exists, deleting it first..."
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # Create the scheduled task to run at startup as SYSTEM with highest privileges
    try
    {
        Register-ScheduledTask -TaskName $taskName `
        -Trigger (New-ScheduledTaskTrigger -AtStartup) `
        -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$env:windir\NetProfileCleanup.ps1`"") `
        -RunLevel Highest `
        -User "SYSTEM" `
        -Force

        Write-Host "Scheduled task `"$taskName`" created successfully."
    }
    catch
    {
        Write-Host "Failed to create scheduled task. $_"
    }
}

Set-ExecutionPolicy Unrestricted

# Run functions
Copy-Item -Path "$PSScriptRoot\ExtractPrograms.ps1" -Destination "$env:windir" -Force

Load-Registry
Install-NetworkProfileCleanup
Install-OpenSSH
