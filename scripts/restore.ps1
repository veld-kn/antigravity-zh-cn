# Antigravity 还原英文原版脚本
# 恢复 app.asar.backup 并重启应用

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Exit-WithPrompt {
    param([int]$ExitCode = 0)
    Write-Host ""
    if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        Write-Host "按回车键退出..." -ForegroundColor Cyan
        $null = Read-Host
    } else {
        Start-Sleep -Seconds 2
    }
    exit $ExitCode
}

# 智能全自动查找 Antigravity 安装目录
function Find-AntigravityDir {
    # 1. 优先检查正在运行的 Antigravity 进程实际加载路径
    try {
        $procs = Get-Process -Name "Antigravity" -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            if ($p.Path -and (Test-Path $p.Path)) {
                $dir = Split-Path -Parent $p.Path
                if ((Test-Path "$dir\resources") -or (Test-Path "$dir\Antigravity.exe")) {
                    return $dir
                }
            }
        }
    } catch {}

    # 2. 检查当前用户 LOCALAPPDATA
    $defaultDir = "$env:LOCALAPPDATA\Programs\antigravity"
    if ((Test-Path "$defaultDir\resources") -or (Test-Path "$defaultDir\Antigravity.exe")) {
        return $defaultDir
    }

    # 3. 扫描本机所有用户目录（解决管理员提权路径漂移）
    try {
        $userDirs = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue
        foreach ($u in $userDirs) {
            $candidate = "$($u.FullName)\AppData\Local\Programs\antigravity"
            if ((Test-Path "$candidate\resources") -or (Test-Path "$candidate\Antigravity.exe")) {
                return $candidate
            }
        }
    } catch {}

    # 4. 检查 Program Files
    $pf = @(
        "${env:ProgramFiles}\antigravity",
        "${env:ProgramFiles(x86)}\antigravity"
    )
    foreach ($p in $pf) {
        if ($p -and (Test-Path "$p\resources")) { return $p }
    }

    return $defaultDir
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     Antigravity 还原英文原版程序       " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$appDir = Find-AntigravityDir
$resourcesDir = Join-Path $appDir "resources"
$targetAsar = Join-Path $resourcesDir "app.asar"
$backupAsar = Join-Path $resourcesDir "app.asar.backup"
$exePath = Join-Path $appDir "Antigravity.exe"

$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$fallbackBackup = Join-Path $repoRoot "tools\app.asar.backup"

# 优先从本机的 app.asar.backup 恢复，次选仓库内置的官方备份
$sourceBackup = $null
if (Test-Path $backupAsar) {
    $sourceBackup = $backupAsar
} elseif (Test-Path $fallbackBackup) {
    $sourceBackup = $fallbackBackup
}

if (-not $sourceBackup) {
    Write-Host "[错误] 未找到任何官方备份文件！无法自动还原。" -ForegroundColor Red
    Exit-WithPrompt 1
}

Write-Host "[检测] 找到 Antigravity 路径: $appDir" -ForegroundColor Gray
Write-Host "正在关闭 Antigravity 及其后台进程..." -ForegroundColor Yellow
Get-Process -Name "Antigravity*", "language_server*" -ErrorAction SilentlyContinue | Stop-Process -Force
$timeout = 10
while ((Get-Process -Name "Antigravity*", "language_server*" -ErrorAction SilentlyContinue) -and ($timeout -gt 0)) {
    Start-Sleep -Milliseconds 500
    $timeout--
}

# 等待文件解锁
$unlocked = $false
for ($i = 0; $i -lt 15; $i++) {
    if (-not (Test-Path $targetAsar)) {
        $unlocked = $true
        break
    }
    try {
        $fileStream = [System.IO.File]::Open($targetAsar, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        if ($fileStream) {
            $fileStream.Close()
            $unlocked = $true
            break
        }
    } catch {
        Start-Sleep -Milliseconds 500
    }
}

Write-Host "正在还原原始备份..." -ForegroundColor Green
Copy-Item $sourceBackup $targetAsar -Force
Write-Host "已成功还原为官方英文原版！" -ForegroundColor Green

Write-Host "`n启动 Antigravity..." -ForegroundColor Cyan
if (Test-Path $exePath) {
    Remove-Item env:ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue
    Start-Process -FilePath $exePath
}

Exit-WithPrompt 0
