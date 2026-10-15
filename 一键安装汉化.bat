@echo off
setlocal
cd /d "%~dp0"
title Antigravity Chinese Localization Installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install.ps1"
if %errorlevel% neq 0 (
    echo.
    echo ================================================================
    echo  Installation failed. If permission was denied, please run as admin.
    echo ================================================================
    pause
)
