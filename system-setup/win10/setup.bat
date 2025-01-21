@echo off
setlocal

:: Define the PowerShell script filename
set "PS_SCRIPT=[dtrh.net]win10-bootstrap.ps1"

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Requesting elevation...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Display banner
echo =================================
echo       TODO: DTRH banner here
echo =================================

:: Warn user about execution policy change
echo WARNING: The execution policy will be temporarily set to allow the PowerShell script to run.

:: Prompt the user for confirmation
choice /c YN /m "Do you want to continue? (Y/N)"
if errorlevel 2 goto no_branch
if errorlevel 1 goto yes_branch

:yes_branch
echo.
echo You chose to continue.
echo The script will override the execution policy for %PS_SCRIPT% and execute it.
pause

:: Construct the full path to the PowerShell script
set "psscript=%~dp0%PS_SCRIPT%"

:: Run the PowerShell script in a new window that won't auto exit
start powershell.exe -NoExit -ExecutionPolicy Bypass -File "%psscript%"
goto end_script

:no_branch
echo.
echo You chose not to continue.
echo No changes will be made.
pause

:end_script
exit /b
