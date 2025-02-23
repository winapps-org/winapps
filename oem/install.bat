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
