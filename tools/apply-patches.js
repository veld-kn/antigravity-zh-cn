/**
 * Antigravity 自动化汉化补丁应用工具
 * 自动提取 app.asar，注入 zh-cn-translate.js 与原生汉化补丁，并重新打包
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function getAntigravityAsarPath() {
  if (process.env.LOCALAPPDATA) {
    const defaultPath = path.join(process.env.LOCALAPPDATA, 'Programs', 'antigravity', 'resources', 'app.asar');
    if (fs.existsSync(defaultPath)) return defaultPath;
  }
  return null;
}

function runCommand(cmd, cwd) {
  console.log(`> ${cmd}`);
  execSync(cmd, { cwd: cwd || process.cwd(), stdio: 'inherit' });
}

async function main() {
  const asarPath = process.argv[2] || getAntigravityAsarPath();

  if (!asarPath || !fs.existsSync(asarPath)) {
    console.error('错误: 未找到 app.asar，请传入 app.asar 的完整路径。');
    console.error('用法: node tools/apply-patches.js "<path-to-app.asar>"');
    process.exit(1);
  }

  console.log(`找到目标 asar: ${asarPath}`);
  const workDir = path.resolve(__dirname, '..', 'build_temp');
  const extractedDir = path.join(workDir, 'app_extracted');
  const distDir = path.join(extractedDir, 'dist');

  // 清理临时目录
  if (fs.existsSync(workDir)) {
    fs.rmSync(workDir, { recursive: true, force: true });
  }
  fs.mkdirSync(workDir, { recursive: true });

  // 1. 解包
  console.log('正在解包 app.asar...');
  runCommand(`npx asar extract "${asarPath}" "${extractedDir}"`);

  // 2. 复制 zh-cn-translate.js
  const srcScript = path.resolve(__dirname, '..', 'src', 'zh-cn-translate.js');
  const destScript = path.join(distDir, 'zh-cn-translate.js');
  console.log(`复制翻译核心: ${srcScript} -> ${destScript}`);
  fs.copyFileSync(srcScript, destScript);

  // 3. 注入 preload.js
  const preloadPath = path.join(distDir, 'preload.js');
  if (fs.existsSync(preloadPath)) {
    let content = fs.readFileSync(preloadPath, 'utf-8');
    if (!content.includes('zh-cn-translate.js')) {
      const injection = `
// ── 简体中文翻译注入 ──
const _zhFs = require("fs");
const _zhPath = require("path");
try {
    require('./zh-cn-translate.js');
} catch (_zhErr2) {
    console.error('[zh-CN] Failed to require translation script:', _zhErr2.message);
}
try {
    const _zhScript = _zhFs.readFileSync(_zhPath.join(__dirname, 'zh-cn-translate.js'), 'utf-8');
    electron_1.webFrame.executeJavaScript(_zhScript).catch(() => {});
} catch (_zhErr) {
    console.error('[zh-CN] Failed to load translation script:', _zhErr.message);
}
// ── 简体中文翻译注入结束 ──
`;
      content = content.replace('const updaterAPI = {', injection + 'const updaterAPI = {');
      fs.writeFileSync(preloadPath, content, 'utf-8');
      console.log('已注入 preload.js');
    }
  }

  // 4. 注入 utils.js
  const utilsPath = path.join(distDir, 'utils.js');
  if (fs.existsSync(utilsPath)) {
    let content = fs.readFileSync(utilsPath, 'utf-8');
    if (!content.includes('zh-cn-translate.js')) {
      const injectFinishLoad = `
            try {
                const zhPath = path_1.default.join(__dirname, 'zh-cn-translate.js');
                if (fs.existsSync(zhPath)) {
                    const zhCode = fs.readFileSync(zhPath, 'utf-8');
                    void win.webContents.executeJavaScript(zhCode);
                }
            } catch (err) {
                console.error('[zh-CN] did-finish-load translation injection error:', err);
            }`;
      const injectDomReady = `
            try {
                const zhPath = path_1.default.join(__dirname, 'zh-cn-translate.js');
                if (fs.existsSync(zhPath)) {
                    const zhCode = fs.readFileSync(zhPath, 'utf-8');
                    void win.webContents.executeJavaScript(zhCode);
                }
            } catch (err) {
                console.error('[zh-CN] dom-ready translation injection error:', err);
            }`;

      content = content.replace("void applyStoredZoomLevel();", "void applyStoredZoomLevel();" + injectFinishLoad);
      content = content.replace("win.webContents.on('dom-ready', () => {", "win.webContents.on('dom-ready', () => {" + injectDomReady);
      fs.writeFileSync(utilsPath, content, 'utf-8');
      console.log('已注入 utils.js');
    }
  }

  // 5. 替换原生文本 (main.js, menu.js, tray.js, updater.js, provisionSplash.js)
  const replaceInFile = (file, map) => {
    const filePath = path.join(distDir, file);
    if (!fs.existsSync(filePath)) return;
    let content = fs.readFileSync(filePath, 'utf-8');
    for (const [from, to] of Object.entries(map)) {
      content = content.split(from).join(to);
    }
    fs.writeFileSync(filePath, content, 'utf-8');
    console.log(`已汉化原生组件: ${file}`);
  };

  replaceInFile('main.js', {
    "label: 'New Window'": "label: '新建窗口'",
    "label: 'No agents running'": "label: '无智能体运行'",
    "label: `Open ${electron_1.app.getName()}`": "label: `打开 ${electron_1.app.getName()}`",
    "label: 'Quit'": "label: '退出'",
    "buttons: ['Cancel', 'Quit']": "buttons: ['取消', '退出']",
    "title: 'Confirm Quit'": "title: '确认退出'",
    "message: 'Are you sure you want to quit?'": "message: '确定要退出吗？'",
    "detail: 'There may be agents or background tasks running.'": "detail: '可能有智能体或后台任务正在运行。'"
  });

  replaceInFile('menu.js', {
    "label: 'New Window'": "label: '新建窗口'",
    "label: 'Docs'": "label: '文档'",
    "label: 'Connect to WSL'": "label: '连接到 WSL'",
    "label: 'Reopen Locally'": "label: '在本地重新打开'"
  });

  const trayPath = path.join(distDir, 'tray.js');
  if (fs.existsSync(trayPath)) {
    let content = fs.readFileSync(trayPath, 'utf-8');
    const trayOld = `countItem.label =\n                (count > 0 ? \`\${count}\` : 'No') +\n                    ' agent' +\n                    (count === 1 ? '' : 's') +\n                    ' running';`;
    const trayNew = `countItem.label =\n                (count > 0 ? \`\${count} 个智能体运行中\` : '无智能体运行');`;
    content = content.replace(trayOld, trayNew);
    fs.writeFileSync(trayPath, content, 'utf-8');
    console.log('已汉化原生组件: tray.js');
  }

  replaceInFile('updater.js', {
    'MenuUpdateStep["CheckForUpdates"] = "Check for Updates";': 'MenuUpdateStep["CheckForUpdates"] = "检查更新";',
    'MenuUpdateStep["CheckingForUpdates"] = "Checking for Updates...";': 'MenuUpdateStep["CheckingForUpdates"] = "正在检查更新...";',
    'MenuUpdateStep["DownloadingUpdate"] = "Downloading Update...";': 'MenuUpdateStep["DownloadingUpdate"] = "正在下载更新...";',
    'MenuUpdateStep["RestartToUpdate"] = "Restart to Update";': 'MenuUpdateStep["RestartToUpdate"] = "重启以更新";',
    "title: 'Check for Updates'": "title: '检查更新'",
    "message: 'No updates available'": "message: '没有可用更新'",
    "buttons: ['OK']": "buttons: ['确定']"
  });

  replaceInFile('provisionSplash.js', {
    'Setting up WSL: ': '正在配置 WSL: '
  });

  // 6. 重新打包
  const outputAsar = path.resolve(__dirname, '..', 'app_zh.asar');
  console.log(`正在打包新 asar: ${outputAsar}...`);
  runCommand(`npx asar pack "${extractedDir}" "${outputAsar}"`);

  console.log('\n========================================');
  console.log('汉化打包完成！生成文件: ' + outputAsar);
  console.log('请运行 scripts/install.bat 将补丁应用到 Antigravity 中。');
  console.log('========================================');
}

main().catch(err => {
  console.error('发生错误:', err);
  process.exit(1);
});
