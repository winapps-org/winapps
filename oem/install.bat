@echo off
REM Copyright (c) 2024 Oskar Manhart
REM All rights reserved.
REM
REM SPDX-License-Identifier: AGPL-3.0-or-later

REG IMPORT C:\OEM\RDPApps.reg

:: Create Powershell network profile cleanup script
(
echo # Get the current network profile name
echo $currentProfile = ^(Get-NetConnectionProfile^).Name
echo.
echo # Get all profiles from the registry
echo $profilesKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles"
echo $profiles = Get-ChildItem -Path $profilesKey
echo.
echo foreach ^($profile in $profiles^) {
echo     $profilePath = "$profilesKey\$($profile.PSChildName)"
echo     $profileName = ^(Get-ItemProperty -Path $profilePath^).ProfileName
echo.
echo     # Remove profiles that don't match the current one
echo     if ^($profileName -ne $currentProfile^) {
echo         Remove-Item -Path $profilePath -Recurse
echo         Write-Host "Deleted profile: $profileName"
echo     }
echo }
echo.
echo # Change the current profile name to "WinApps"
echo $profiles = Get-ChildItem -Path $profilesKey
echo foreach ^($profile in $profiles^) {
echo     $profilePath = "$profilesKey\$($profile.PSChildName)"
echo     $profileName = ^(Get-ItemProperty -Path $profilePath^).ProfileName
echo.
echo     if ^($profileName -eq $currentProfile^) {
echo         # Update the profile name
echo         Set-ItemProperty -Path $profilePath -Name "ProfileName" -Value "WinApps"
echo         Write-Host "Renamed profile to: WinApps"
echo     }
echo }
) > %windir%\NetProfileCleanup.ps1

:: Create network profile cleanup scheduled task
set "taskname=NetworkProfileCleanup"
set "command=powershell.exe -ExecutionPolicy Bypass -File "%windir%\NetProfileCleanup.ps1^""

schtasks /query /tn "%taskname%" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Task "%taskname%" already exists, deleting it first...
    schtasks /delete /tn "%taskname%" /f
)

schtasks /create /tn "%taskname%" /tr "%command%" /sc onstart /ru "SYSTEM" /rl HIGHEST /f
if %ERRORLEVEL% equ 0 (
    echo Scheduled task "%taskname%" created successfully.
) else (
    echo Failed to create scheduled task.
)
