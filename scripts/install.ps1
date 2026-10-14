# Antigravity 简体中文汉化一键安装程序
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "             Antigravity 简体中文汉化一键安装程序           " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$appDir = "$env:LOCALAPPDATA\Programs\antigravity"
$targetAsar = "$appDir\resources\app.asar"
$backupAsar = "$appDir\resources\app.asar.backup"
$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$sourceAsar = Join-Path $repoRoot "app_zh.asar"
$patchScript = Join-Path $repoRoot "tools\apply-patches.js"

if (-not (Test-Path $targetAsar)) {
    Write-Host "[错误] 未检测到 Antigravity 安装路径 ($targetAsar)！" -ForegroundColor Red
    Write-Host "请确认已安装 Antigravity 桌面客户端。" -ForegroundColor Yellow
    Read-Host "按回车键退出..."
    exit 1
}

# 1. 检查并关闭进程
Write-Host "[1/4] 正在关闭 Antigravity 及其后台服务..." -ForegroundColor Yellow
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

# 2. 备份原始文件
Write-Host "[2/4] 正在检查原版备份..." -ForegroundColor Yellow
if (-not (Test-Path $backupAsar)) {
    Write-Host "      正在创建官方原版备份 -> app.asar.backup" -ForegroundColor Green
    Copy-Item $targetAsar $backupAsar -Force
} else {
    Write-Host "      已存在官方原版备份: app.asar.backup" -ForegroundColor Gray
}

# 3. 获取或生成汉化包
Write-Host "[3/4] 正在准备汉化包..." -ForegroundColor Yellow
if (Test-Path $sourceAsar) {
    Write-Host "      发现现有汉化包 app_zh.asar，直接安装..." -ForegroundColor Green
    Copy-Item $sourceAsar $targetAsar -Force
} else {
    Write-Host "      正在自动执行零依赖打补丁流程..." -ForegroundColor Cyan
    # 查找可用 Node 环境
    $nodeExe = $null
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeExe = "node"
    } elseif (Test-Path "$appDir\Antigravity.exe") {
        $nodeExe = "$appDir\Antigravity.exe"
        $env:ELECTRON_RUN_AS_NODE = "1"
        Write-Host "      使用内置运行引擎: Antigravity Node" -ForegroundColor Gray
    }
    
    if (-not $nodeExe) {
        Write-Host "[错误] 未能找到 Node 运行环境！" -ForegroundColor Red
        Read-Host "按回车键退出..."
        exit 1
    }
    
    & $nodeExe $patchScript --install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[错误] 补丁应用失败！" -ForegroundColor Red
        Read-Host "按回车键退出..."
        exit 1
    }
}

# 4. 验证并启动
Write-Host "[4/4] 验证安装并启动 Antigravity..." -ForegroundColor Green
$installedSize = (Get-Item $targetAsar).Length
Write-Host "      补丁文件大小: $([math]::Round($installedSize / 1MB, 2)) MB" -ForegroundColor Gray

$exePath = "$appDir\Antigravity.exe"
if (Test-Path $exePath) {
    Start-Process -FilePath $exePath
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "    🎉 恭喜！Antigravity 简体中文汉化已成功安装并生效！      " -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  • 界面完全汉化：1,310+ 个 UI 词条、快捷键、斜杠命令与设置" -ForegroundColor Gray
    Write-Host "  • 动态智能匹配：思考耗时、工作时长、任务状态实时翻译" -ForegroundColor Gray
    Write-Host "  • 原生深度汉化：系统菜单、托盘图标、更新提示、退出对话框" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  💡 如需恢复官方英文原版，随时双击运行【一键恢复原版.bat】即可。" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Green
} else {
    Write-Host "请手动打开 Antigravity。" -ForegroundColor Yellow
}

Write-Host ""
Start-Sleep -Seconds 3
