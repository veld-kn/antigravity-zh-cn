# Antigravity 还原英文原版脚本
# 恢复 app.asar.backup 并重启应用

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     Antigravity 还原英文原版程序       " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$targetAsar = "$env:LOCALAPPDATA\Programs\antigravity\resources\app.asar"
$backupAsar = "$env:LOCALAPPDATA\Programs\antigravity\resources\app.asar.backup"

if (-not (Test-Path $backupAsar)) {
    Write-Host "错误: 未找到备份文件 ($backupAsar)！无法自动还原。" -ForegroundColor Red
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

Write-Host "正在还原原始备份..." -ForegroundColor Green
Copy-Item $backupAsar $targetAsar -Force
Write-Host "已成功还原为英文原版！" -ForegroundColor Green

Write-Host "`n启动 Antigravity..." -ForegroundColor Cyan
$exePath = "$env:LOCALAPPDATA\Programs\antigravity\Antigravity.exe"
if (Test-Path $exePath) {
    Start-Process -FilePath $exePath
}

Start-Sleep -Seconds 3
