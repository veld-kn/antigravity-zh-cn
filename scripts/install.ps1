# Antigravity 简体中文汉化一键安装程序
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

    # 3. 扫描本机所有用户目录（完美解决以管理员身份运行时 LOCALAPPDATA 漂移至 Administrator 的问题）
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

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "             Antigravity 简体中文汉化一键安装程序           " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$appDir = Find-AntigravityDir
$resourcesDir = Join-Path $appDir "resources"
$targetAsar = Join-Path $resourcesDir "app.asar"
$backupAsar = Join-Path $resourcesDir "app.asar.backup"
$exePath = Join-Path $appDir "Antigravity.exe"

$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$sourceAsar = Join-Path $repoRoot "app_zh.asar"
$patchScript = Join-Path $repoRoot "tools\apply-patches.js"
$fallbackBackup = Join-Path $repoRoot "tools\app.asar.backup"

# 检查客户端是否安装（只要存在 exe、resources 目录或已有的 asar 其中之一即判定已安装）
$isInstalled = (Test-Path $exePath) -or (Test-Path $resourcesDir) -or (Test-Path $targetAsar)
if (-not $isInstalled) {
    Write-Host "[错误] 未检测到 Antigravity 安装路径 ($appDir)！" -ForegroundColor Red
    Write-Host "请确认已安装 Antigravity 桌面客户端。" -ForegroundColor Yellow
    Exit-WithPrompt 1
}

Write-Host "[检测] 找到 Antigravity 路径: $appDir" -ForegroundColor Gray

# 确保 resources 目录存在
if (-not (Test-Path $resourcesDir)) {
    New-Item -ItemType Directory -Path $resourcesDir -Force | Out-Null
}

# 1. 检查并关闭进程与后台安装器
Write-Host "[1/4] 正在关闭 Antigravity 及其后台服务..." -ForegroundColor Yellow
Get-Process -Name "Antigravity*", "language_server*", "installer*" -ErrorAction SilentlyContinue | Stop-Process -Force
$timeout = 10
while ((Get-Process -Name "Antigravity*", "language_server*", "installer*" -ErrorAction SilentlyContinue) -and ($timeout -gt 0)) {
    Start-Sleep -Milliseconds 500
    $timeout--
}

# 清理待执行的后台更新缓存，防止官方更新程序覆盖汉化
$updaterPending = "$env:LOCALAPPDATA\antigravity-updater\pending"
if (Test-Path $updaterPending) {
    Remove-Item -Recurse -Force "$updaterPending\*" -ErrorAction SilentlyContinue
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

# 2. 备份原始文件
Write-Host "[2/4] 正在检查原版备份..." -ForegroundColor Yellow
if (Test-Path $targetAsar) {
    if (-not (Test-Path $backupAsar)) {
        $size = (Get-Item $targetAsar).Length
        # 官方原版约为 4.4MB，汉化版约为 17MB
        if ($size -lt 10MB) {
            Write-Host "      正在创建官方原版备份 -> app.asar.backup" -ForegroundColor Green
            Copy-Item $targetAsar $backupAsar -Force
        } elseif (Test-Path $fallbackBackup) {
            Write-Host "      从安装包注入官方纯净原版备份..." -ForegroundColor Green
            Copy-Item $fallbackBackup $backupAsar -Force
        }
    } else {
        Write-Host "      已存在官方原版备份: app.asar.backup" -ForegroundColor Gray
    }
} elseif (Test-Path $fallbackBackup) {
    Write-Host "      从安装包准备官方纯净原版备份..." -ForegroundColor Green
    Copy-Item $fallbackBackup $backupAsar -Force
}

# 3. 获取或生成汉化包并安装
Write-Host "[3/4] 正在准备汉化包..." -ForegroundColor Yellow
if (Test-Path $sourceAsar) {
    Write-Host "      发现现有汉化包 app_zh.asar，直接安装..." -ForegroundColor Green
    Copy-Item $sourceAsar $targetAsar -Force
} else {
    Write-Host "      正在自动执行零依赖打补丁流程..." -ForegroundColor Cyan
    $nodeExe = $null
    $useAntigravityNode = $false
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeExe = "node"
    } elseif (Test-Path $exePath) {
        $nodeExe = $exePath
        $useAntigravityNode = $true
        Write-Host "      使用内置运行引擎: Antigravity Node" -ForegroundColor Gray
    }
    
    if (-not $nodeExe) {
        Write-Host "[错误] 未能找到 Node 运行环境！" -ForegroundColor Red
        Exit-WithPrompt 1
    }
    
    if ($useAntigravityNode) { $env:ELECTRON_RUN_AS_NODE = "1" }
    $baseAsar = if (Test-Path $backupAsar) { $backupAsar } else { $targetAsar }
    & $nodeExe $patchScript $baseAsar --install
    $patchExitCode = $LASTEXITCODE
    if ($useAntigravityNode) { Remove-Item env:ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue }
    
    if ($patchExitCode -ne 0) {
        Write-Host "[错误] 补丁应用失败！" -ForegroundColor Red
        Exit-WithPrompt 1
    }
}

# 4. 验证并启动
Write-Host "[4/4] 验证安装并启动 Antigravity..." -ForegroundColor Green
if (Test-Path $targetAsar) {
    $installedSize = (Get-Item $targetAsar).Length
    Write-Host "      补丁文件大小: $([math]::Round($installedSize / 1MB, 2)) MB" -ForegroundColor Gray
}

if (Test-Path $exePath) {
    Remove-Item env:ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue
    Start-Process -FilePath $exePath
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "    🎉 恭喜！Antigravity 简体中文汉化已成功安装并生效！      " -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  • 界面完全汉化：1,320+ 个 UI 词条、快捷键、斜杠命令与设置" -ForegroundColor Gray
    Write-Host "  • 动态智能匹配：思考耗时、工作时长、相对时间、任务状态实时翻译" -ForegroundColor Gray
    Write-Host "  • 原生深度汉化：系统菜单、托盘图标、更新提示、退出对话框" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  💡 如需恢复官方英文原版，随时双击运行【一键恢复原版.bat】即可。" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Green
} else {
    Write-Host "请手动打开 Antigravity。" -ForegroundColor Yellow
}

Exit-WithPrompt 0
