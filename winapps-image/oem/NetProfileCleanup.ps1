# Get the current network profile name
$currentProfile = (Get-NetConnectionProfile).Name

# Get all profiles from the registry
$profilesKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles"
$profiles = Get-ChildItem -Path $profilesKey

foreach ($profile in $profiles) {
    $profilePath = "$profilesKey\$($profile.PSChildName)"
    $profileName = (Get-ItemProperty -Path $profilePath).ProfileName

    # Remove profiles that don't match the current one
    if ($profileName -ne $currentProfile) {
        Remove-Item -Path $profilePath -Recurse
        Write-Host "Deleted profile: $profileName"
    }
}

# Change the current profile name to "WinApps"
$profiles = Get-ChildItem -Path $profilesKey
foreach ($profile in $profiles) {
    $profilePath = "$profilesKey\$($profile.PSChildName)"
    $profileName = (Get-ItemProperty -Path $profilePath).ProfileName

    if ($profileName -eq $currentProfile) {
        # Update the profile name
        Set-ItemProperty -Path $profilePath -Name "ProfileName" -Value "WinApps"
        Write-Host "Renamed profile to: WinApps"
    }
}
