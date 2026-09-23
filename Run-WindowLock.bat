@echo off
set "SCRIPT=%~dp0WindowLock.ps1"

if not exist "%SCRIPT%" (
    echo ERROR: WindowLock.ps1 was not found.
    echo Expected location: "%SCRIPT%"
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -NoLogo -File "%SCRIPT%"
exit /b %ERRORLEVEL%