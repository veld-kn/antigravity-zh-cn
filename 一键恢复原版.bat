@echo off
setlocal
cd /d "%~dp0"
title Antigravity Restore Original
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\restore.ps1"
if %errorlevel% neq 0 (
    echo.
    echo ================================================================
    echo  Restore failed. If permission was denied, please run as admin.
    echo ================================================================
    pause
)
