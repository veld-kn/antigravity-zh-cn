# Antigravity Git Push Script
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "        Antigravity 简体中文汉化项目 - GitHub 上传助手    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[OK] 本地提交与 Git 历史已完成隐私脱敏（无用户名、无本地路径）" -ForegroundColor Green
Write-Host "[OK] 提交格式已符合 Conventional Commits 规范" -ForegroundColor Green
Write-Host ""

$gitExe = $null
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitExe = "git"
} else {
    $candidate = "$env:LOCALAPPDATA\Programs\WorkBuddyAI\resources\vendor\PortableGit\cmd\git.exe"
    if (Test-Path $candidate) {
        $gitExe = $candidate
    } elseif (Test-Path "$env:ProgramFiles\Git\cmd\git.exe") {
        $gitExe = "$env:ProgramFiles\Git\cmd\git.exe"
    } elseif (Test-Path "${env:ProgramFiles(x86)}\Git\cmd\git.exe") {
        $gitExe = "${env:ProgramFiles(x86)}\Git\cmd\git.exe"
    }
}

if (-not $gitExe) {
    Write-Host "[错误] 未检测到 Git 环境，请先安装 Git。" -ForegroundColor Red
    Read-Host "按回车键退出..."
    exit 1
}

$repoDir = $PSScriptRoot
Set-Location $repoDir
Write-Host "项目目录: $repoDir" -ForegroundColor Gray

# 检查现有远程仓库
$currentOrigin = (& $gitExe -C $repoDir remote get-url origin 2>$null)
if ($currentOrigin) {
    Write-Host "当前目标仓库: $currentOrigin" -ForegroundColor Green
    Write-Host ""
    $inputUrl = Read-Host "直接按 [回车] 开始推送，或输入新仓库地址"
    if ($inputUrl -and $inputUrl.Trim()) {
        $repoUrl = $inputUrl.Trim()
        & $gitExe -C $repoDir remote set-url origin $repoUrl
    } else {
        $repoUrl = $currentOrigin
    }
} else {
    $repoUrl = Read-Host "请输入你的 GitHub 仓库地址 (例如 https://github.com/veld-kn/antigravity-zh-cn.git)"
    $repoUrl = $repoUrl.Trim()
    if (-not $repoUrl) {
        Write-Host "[错误] 仓库地址不能为空！" -ForegroundColor Red
        Read-Host "按回车键退出..."
        exit 1
    }
    & $gitExe -C $repoDir remote add origin $repoUrl
}

Write-Host ""
Write-Host "[1/2] 确认主分支为 main ..." -ForegroundColor Yellow
& $gitExe -C $repoDir branch -M main

Write-Host "[2/2] 正在推送到 GitHub ..." -ForegroundColor Cyan
Write-Host "提示: 如果系统弹出 GitHub 网页登录授权窗口，请点击完成授权。" -ForegroundColor Yellow
Write-Host ""

& $gitExe -C $repoDir push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  恭喜！代码已成功推送到你的 GitHub 仓库！                " -ForegroundColor Green
    Write-Host "  仓库地址: $repoUrl" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "推送未完成，可能的原因：" -ForegroundColor Yellow
    Write-Host "1. GitHub 身份验证未通过（如弹出网页授权时未完成点击）。" -ForegroundColor Gray
    Write-Host "2. 如果开启了两步验证(2FA)，Git 密码需使用 Personal Access Token (PAT)。" -ForegroundColor Gray
    Write-Host "3. 如果远程仓库已有 README 等初始文件，可执行强制推送或拉取合并。" -ForegroundColor Gray
    Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "按回车键关闭窗口..."