@echo off
chcp 65001 >nul
title Antigravity 简体中文汉化补丁安装
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if %errorlevel% neq 0 (
    echo.
    echo 安装失败或需要以管理员身份运行。
    pause
)
