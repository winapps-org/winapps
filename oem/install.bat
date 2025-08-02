@echo off
title WinApps Setup Wizard

REM Check for administrative privileges
fltmc >nul 2>&1 || (
    echo [INFO] Script not running as administrator. Attempting to relaunch with elevation...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b 0
)

REM Confirm the user wants to proceed with setup
echo ============================================
echo             WinApps Setup Wizard
echo ============================================
echo.
echo Press any key to continue or close this window to cancel...
pause >nul
echo.
echo [INFO] Starting setup...

REM Apply RDP and system configuration tweaks
echo [INFO] Importing "RDPApps.reg"...
reg import "%~dp0RDPApps.reg" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [SUCCESS] Imported "RDPApps.reg".
) else (
    echo [ERROR] Failed to import "RDPApps.reg".
)

REM Configure the system clock to use UTC instead of local time
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

REM Create a startup task to clean up stale network profiles
echo [INFO] Creating network profile cleanup task...

REM Initialise values required to create the startup task
set "scriptpath=%windir%\NetProfileCleanup.ps1"
set "taskname=WinApps_NetworkProfileCleanup"
set "command=powershell.exe -ExecutionPolicy Bypass -File ""%scriptpath%"""

REM Copy the script to the Windows directory
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

echo.
echo Press any key to exit...
pause >nul
