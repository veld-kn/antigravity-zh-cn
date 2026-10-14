# Antigravity 简体中文汉化补丁

> Google Antigravity 桌面应用（Electron）的非官方简体中文本地化补丁。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows)](https://www.microsoft.com/windows)

---

## ✨ 功能概览

- **全界面汉化**：覆盖 1,084+ 个 UI 文本条目，包括菜单栏、设置页面、模型/配额页面、通知、快捷键面板、斜杠命令、技能描述等
- **原生层汉化**：系统菜单（File/Help）、托盘图标、退出确认对话框、更新提示等 Electron 原生组件
- **动态翻译引擎**：基于 `MutationObserver` 实时监听 DOM 变化，支持 React SPA 路由切换、弹窗、抽屉组件的增量翻译
- **正则模式匹配**：智能处理动态文本（如 "3 agents running" → "3 个智能体运行中"、时间相对值、配额信息等）
- **Shadow DOM 穿透**：自动遍历 Shadow Root 确保 Web Components 内部文本也被翻译
- **一键安装/卸载**：提供桌面安装与还原脚本

## 📦 项目结构

```
antigravity-zh-cn/
├── README.md                  # 本文件
├── LICENSE                    # MIT 许可证
├── .gitignore
├── src/
│   └── zh-cn-translate.js     # 核心翻译引擎（DOM 深度翻译脚本）
├── patches/
│   ├── preload.patch          # preload.js 注入补丁
│   ├── utils.patch            # utils.js WebContents 注入补丁
│   ├── main.patch             # main.js 原生菜单/对话框汉化
│   ├── menu.patch             # menu.js 应用菜单汉化
│   ├── tray.patch             # tray.js 托盘菜单汉化
│   ├── updater.patch          # updater.js 更新提示汉化
│   └── provisionSplash.patch  # provisionSplash.js WSL 配置提示汉化
├── scripts/
│   ├── install.ps1            # PowerShell 安装脚本
│   ├── install.bat            # 一键安装入口（双击运行）
│   ├── restore.ps1            # PowerShell 还原脚本
│   └── restore.bat            # 一键还原入口（双击运行）
└── tools/
    └── apply-patches.js       # 自动解包、打补丁、重新打包工具
```

## 🚀 快速开始

### 前置要求

- Windows 10/11
- [Google Antigravity](https://antigravity.google) 桌面版已安装
- [Node.js](https://nodejs.org/) >= 18（用于 `asar` 解包/打包）

### 安装步骤

#### 方法一：自动安装（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/<your-username>/antigravity-zh-cn.git
cd antigravity-zh-cn

# 2. 安装依赖
npm install

# 3. 运行自动打补丁工具
node tools/apply-patches.js

# 4. 双击 scripts/install.bat 安装汉化包
```

#### 方法二：手动安装

1. 关闭 Antigravity 应用
2. 找到安装目录下的 `resources/app.asar`（通常位于 `%LOCALAPPDATA%\Programs\antigravity\resources\`）
3. 备份原始 `app.asar`
4. 使用 `npx asar extract app.asar app_extracted` 解包
5. 将 `src/zh-cn-translate.js` 复制到 `app_extracted/dist/` 目录
6. 按照 `patches/` 目录下的补丁说明手动修改对应文件
7. 使用 `npx asar pack app_extracted app.asar` 重新打包
8. 替换原始 `app.asar` 并重启应用

### 卸载 / 还原

```bash
# 双击运行还原脚本
scripts/restore.bat
```

或手动将备份的 `app.asar.backup` 恢复为 `app.asar`。

## 🔧 技术架构

### 翻译引擎（zh-cn-translate.js）

```
┌─────────────────────────────────────────────────────┐
│                   翻译引擎流程                        │
├─────────────────────────────────────────────────────┤
│  1. 精确匹配 (TRANSLATIONS 字典)                     │
│  2. 大小写不敏感匹配 (TRANSLATIONS_LOWER)             │
│  3. 末尾标点自动适配 ("Settings:" → "设置：")          │
│  4. 正则模式匹配 (PATTERN_TRANSLATIONS)               │
│     - 动态计数: "3 agents running" → "3 个智能体运行中"│
│     - 时间相对值: "5 minutes ago" → "5 分钟前"        │
│     - 技能描述前缀匹配（处理 DOM 截断的 ...）          │
├─────────────────────────────────────────────────────┤
│  注入方式:                                           │
│  - preload.js: webFrame.executeJavaScript            │
│  - utils.js: did-finish-load + dom-ready 双重注入     │
│  监听方式:                                           │
│  - MutationObserver (childList + characterData)       │
│  - requestAnimationFrame 批量合并                     │
│  - 1s 定时轮询兜底                                   │
│  - Shadow DOM 穿透递归                                │
└─────────────────────────────────────────────────────┘
```

### 原生层补丁

| 文件 | 汉化内容 |
|------|---------|
| `main.js` | 托盘菜单项（新建窗口、打开、退出）、退出确认对话框 |
| `menu.js` | 应用菜单（File → 新建窗口, Help → 文档, 连接到 WSL） |
| `tray.js` | 托盘状态文本（"N agents running" → "N 个智能体运行中"） |
| `updater.js` | 更新检查菜单项、无可用更新对话框 |
| `provisionSplash.js` | WSL 配置进度提示 |

## 📋 翻译覆盖范围

| 区域 | 覆盖状态 |
|------|---------|
| 侧边栏（对话列表、项目、定时任务） | ✅ 完成 |
| 设置 - 通用 | ✅ 完成 |
| 设置 - 外观 | ✅ 完成 |
| 设置 - 模型/配额 | ✅ 完成 |
| 设置 - 通知 | ✅ 完成 |
| 设置 - 开发者 | ✅ 完成 |
| 设置 - 技能与自定义 | ✅ 完成 |
| 快捷键面板 | ✅ 完成 |
| `/` 斜杠命令菜单 | ✅ 完成 |
| 技能/插件描述 | ✅ 完成 |
| 系统菜单 & 托盘 | ✅ 完成 |
| 退出确认对话框 | ✅ 完成 |
| 更新提示 | ✅ 完成 |
| 动态文本（时间、计数等） | ✅ 完成 |
| 搜索/输入框 placeholder | ✅ 完成 |
| 工具提示 (tooltip) | ✅ 完成 |

## 🤝 贡献指南

欢迎提交 PR 改进翻译质量或增加遗漏的翻译条目！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/improve-translations`)
3. 在 `src/zh-cn-translate.js` 中的 `TRANSLATIONS` 字典或 `PATTERN_TRANSLATIONS` 正则数组中添加/修改翻译
4. 提交更改 (`git commit -m 'feat: 补充 XX 页面翻译'`)
5. 推送到远程分支 (`git push origin feature/improve-translations`)
6. 创建 Pull Request

### 翻译规范

- 保持简洁专业的技术用语风格
- 专有名词（如 Antigravity、Gemini、MCP）保持英文
- 括号内的英文缩写保留（如 "最佳结果评估 (BoN)"）
- 标点符号使用中文全角标点

## ⚠️ 免责声明

- 本项目为**非官方**社区汉化补丁，与 Google 无关
- 修改 `app.asar` 可能影响应用稳定性，请自行备份
- 应用更新后可能需要重新安装补丁
- 仅供学习和个人使用

## 📄 许可证

[MIT License](LICENSE)
