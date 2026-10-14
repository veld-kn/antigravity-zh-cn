@echo off
chcp 65001 >nul
title Antigravity 还原英文原版
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore.ps1"
if %errorlevel% neq 0 (
    echo.
    echo 还原失败。
    pause
)
