# Antigravity 汉化补丁安装脚本
# 支持动态路径与安全锁检测，不含任何个人信息

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Antigravity 简体中文汉化补丁安装程序  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$targetAsar = "$env:LOCALAPPDATA\Programs\antigravity\resources\app.asar"
$backupAsar = "$env:LOCALAPPDATA\Programs\antigravity\resources\app.asar.backup"

# 查找补丁源文件 (优先同级或上级目录下的 app_zh.asar)
$sourceAsar = Join-Path $PSScriptRoot "..\app_zh.asar"
if (-not (Test-Path $sourceAsar)) {
    $sourceAsar = "$PSScriptRoot\app_zh.asar"
}

if (-not (Test-Path $targetAsar)) {
    Write-Host "错误: 未找到 Antigravity 安装目录 ($targetAsar)！" -ForegroundColor Red
    pause
    exit 1
}

if (-not (Test-Path $sourceAsar)) {
    Write-Host "错误: 未找到汉化补丁文件 app_zh.asar！" -ForegroundColor Red
    Write-Host "请先运行 'node tools/apply-patches.js' 生成补丁包。" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "正在关闭 Antigravity 及其后台进程..." -ForegroundColor Yellow
Get-Process -Name "Antigravity", "language_server" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# 等待文件解锁
$unlocked = $false
for ($i = 0; $i -lt 15; $i++) {
    try {
        $fileStream = [System.IO.File]::Open($targetAsar, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        if ($fileStream) {
            $fileStream.Close()
            $unlocked = $true
            break
        }
    } catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $unlocked) {
    Write-Host "警告: 文件仍在被占用，尝试强行替换..." -ForegroundColor Red
}

# 备份原文件
if (-not (Test-Path $backupAsar)) {
    Write-Host "正在创建原始文件备份 -> app.asar.backup" -ForegroundColor Green
    Copy-Item $targetAsar $backupAsar -Force
} else {
    Write-Host "已存在原版备份: $backupAsar" -ForegroundColor Gray
}

# 替换补丁
Write-Host "正在安装汉化包..." -ForegroundColor Green
Copy-Item $sourceAsar $targetAsar -Force

$installedSize = (Get-Item $targetAsar).Length
Write-Host "安装完成！补丁大小: $installedSize 字节" -ForegroundColor Green

Write-Host "`n启动 Antigravity..." -ForegroundColor Cyan
$exePath = "$env:LOCALAPPDATA\Programs\antigravity\Antigravity.exe"
if (Test-Path $exePath) {
    Start-Process -FilePath $exePath
    Write-Host "Antigravity 已重启，汉化已生效！" -ForegroundColor Green
} else {
    Write-Host "请手动打开 Antigravity。" -ForegroundColor Yellow
}

Start-Sleep -Seconds 3
