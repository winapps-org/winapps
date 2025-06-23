@echo off

reg import %~dp0\RDPApps.reg

if exists %~dp0\Container.reg (
    reg import %~dp0\Container.reg
)

REM Create network profile cleanup scheduled task
copy %~dp0\NetProfileCleanup.ps1 %windir%
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
