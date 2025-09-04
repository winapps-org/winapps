@echo off
title WinApps Setup Wizard

:: Check for administrative privileges
fltmc >nul 2>&1 || (
    echo [INFO] Script not running as administrator. Attempting to relaunch with elevation...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

echo ============================================
echo             WinApps Setup Wizard
echo ============================================
echo.
echo [INFO] Starting setup...

:: Apply RDP and system configuration tweaks
echo [INFO] Importing "RDPApps.reg"...
if exist "%~dp0RDPApps.reg" (
    reg import "%~dp0RDPApps.reg" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo [SUCCESS] Imported "RDPApps.reg".
    ) else (
        echo [ERROR] Failed to import "RDPApps.reg".
    )
) else (
    echo [ERROR] "RDPApps.reg" not found. Skipping...
)

:: Allow Remote Desktop connections through the firewall
echo [INFO] Allowing Remote Desktop connections through the firewall...
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
  -Command "if (Get-Command Enable-NetFirewallRule -ErrorAction SilentlyContinue) { try { Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction Stop; exit 0 } catch { exit 1 } } else { exit 2 }" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [SUCCESS] Firewall changes applied successfully.
) else (
    :: Fallback to using 'netsh' to make the firewall modification
    netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo [SUCCESS] Firewall changes applied successfully.
    ) else (
        echo [ERROR] Failed to apply firewall changes.
        echo         Please manually enable Remote Desktop via 'Settings ► System ► Remote Desktop'.
    )
)

:: Configure the system clock to use UTC instead of local time
if exist "%~dp0Container.reg" (
    echo [INFO] Importing "Container.reg"...
    reg import "%~dp0Container.reg" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo [SUCCESS] Imported "Container.reg".
    ) else (
        echo [ERROR] Failed to import "Container.reg".
    )
) else (
    echo [WARNING] "Container.reg" not found. Skipping...
)

:: Create a startup task to clean up stale network profiles
echo [INFO] Creating network profile cleanup task...

:: Initialise values required to create the startup task
set "scriptpath=%windir%\NetProfileCleanup.ps1"
set "taskname=WinApps_NetworkProfileCleanup"
set "command=powershell.exe -ExecutionPolicy Bypass -File ""%scriptpath%"""

:: Copy the script to the Windows directory
copy /Y "%~dp0NetProfileCleanup.ps1" "%scriptpath%" >nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to copy "NetProfileCleanup.ps1" to "%windir%".
) else (
    schtasks /create /tn "%taskname%" /tr "%command%" /sc onstart /ru "SYSTEM" /rl HIGHEST /f >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo [SUCCESS] Created scheduled task "%taskname%".
    ) else (
        echo [ERROR] Failed to create scheduled task "%taskname%".
    )
)

REM Create time sync task to be run by the user at login
copy %~dp0\TimeSync.ps1 %windir%
set "taskname2=TimeSync"
set "command2=powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%windir%\TimeSync.ps1\""

schtasks /query /tn "%taskname2%" >nul
if %ERRORLEVEL% equ 0 (
    echo %DATE% %TIME% Task "%taskname2%" already exists, skipping creation.
) else (
    schtasks /create /tn "%taskname2%" /tr "%command2%" /sc onlogon /rl HIGHEST /f
    if %ERRORLEVEL% equ 0 (
        echo %DATE% %TIME% Scheduled task "%taskname2%" created successfully.
    ) else (
        echo %DATE% %TIME% Failed to create scheduled task %taskname2%.
    )
)
