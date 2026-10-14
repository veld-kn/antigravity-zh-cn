@echo off
chcp 65001 >nul
title Antigravity 一键恢复原版
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\restore.ps1"
if %errorlevel% neq 0 (
    echo.
    echo 恢复未成功完成。如果提示权限不足，请尝试右键以管理员身份运行。
    pause
)
