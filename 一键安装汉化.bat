@echo off
chcp 65001 >nul
title Antigravity 简体中文汉化一键安装
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install.ps1"
if %errorlevel% neq 0 (
    echo.
    echo 安装未成功完成。如果提示权限不足，请尝试右键以管理员身份运行。
    pause
)
