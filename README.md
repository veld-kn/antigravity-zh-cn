# Antigravity 简体中文汉化补丁

> **Google Antigravity 桌面应用（Electron）全界面深度简体中文本地化补丁。**  
> 专为中文开发者与新人打造，**0 环境依赖、一键双击安装/还原、全界面深度汉化**。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![Antigravity: 2.22+](https://img.shields.io/badge/Antigravity-v2.22+-green.svg)](https://antigravity.google)

---

## 🌟 核心亮点

- ⚡ **小白新人友好（0 依赖）**：无需额外安装 Node.js、无需运行 npm 或复杂命令行，解压后**双击即装**！
- 🎯 **全界面完全汉化**：收录 **1,310+** 个核心 UI 词条，涵盖侧边栏、对话画布、设置面板、模型选择器、斜杠命令菜单、快捷键面板等。
- 🧠 **动态智能翻译引擎**：
  - **思考耗时动态匹配**：如 `Thought for 8s` → `思考了 8 秒`、`Worked for 12m` → `已工作 12 分钟`
  - **动态目标与状态**：`1 active goal` → `1 个进行中的目标`、`No more older messages` → `没有更早的消息了`
  - **提示与占位符**：`Ask anything, @ to mention, / for actions` → `随时提问，输入 @ 引用，输入 / 执行操作`
- 🖥️ **原生层深度汉化**：系统顶部菜单（File/Help）、托盘右键菜单、退出确认对话框、更新检测弹窗等 Electron 原生组件全汉化。
- 🛡️ **安全无忧·一键还原**：安装时自动备份官方原始文件，随时双击【一键恢复原版】即可 100% 无损还原。

---

## 🚀 极速上手（新人推荐）

### 1. 一键安装汉化

1. 下载或克隆本项目到本地任意目录。
2. 直接双击运行根目录下的 **`一键安装汉化.bat`**。
3. 脚本会自动安全关闭应用、创建官方原版备份、注入汉化核心并重启 Antigravity。
4. 打开应用，即刻享受全中文交互！

### 2. 一键恢复原版

若后续需要恢复为官方纯英文界面：
- 直接双击根目录下的 **`一键恢复原版.bat`** 即可瞬间还原。

---

## 💻 进阶开发者使用

如果你已经配置了本地 Node.js 开发环境，也可以通过命令行手动构建与安装：

```bash
# 1. 克隆仓库
git clone https://github.com/veld-kn/antigravity-zh-cn.git
cd antigravity-zh-cn

# 2. 生成独立汉化包 (app_zh.asar)
node tools/apply-patches.js

# 3. 直接应用到当前系统的 Antigravity 中
node tools/apply-patches.js --install
```

> 💡 **原理揭秘**：本项目内置了经过深度优化的零依赖独立打包引擎（`tools/asar.js`），并在安装脚本中支持直接借用 Antigravity 自身的运行环境（`ELECTRON_RUN_AS_NODE=1`），因此即使未安装全局 Node.js 的电脑也能流畅运行所有打包与解包流程。

---

## 📦 项目结构

```
antigravity-zh-cn/
├── 一键安装汉化.bat            # 【推荐】小白新人双击一键安装
├── 一键恢复原版.bat            # 【推荐】小白新人双击一键还原英文
├── install.bat                 # 安装入口别名
├── restore.bat                 # 还原入口别名
├── push.bat / push.ps1         # GitHub 一键推送助手
├── README.md                   # 项目说明文档
├── LICENSE                     # MIT 许可证
├── package.json
├── src/
│   └── zh-cn-translate.js      # 核心翻译引擎（1,310+ 词条、DOM 深度遍历、Shadow DOM 穿透、MutationObserver 实时监听）
├── patches/                    # 原生层代码差异补丁归档
│   ├── main.patch              # main.js 原生菜单/退出对话框汉化
│   ├── menu.patch              # menu.js 应用程序菜单汉化
│   ├── tray.patch              # tray.js 托盘菜单汉化
│   ├── updater.patch           # updater.js 更新检查汉化
│   └── provisionSplash.patch   # provisionSplash.js WSL 配置提示汉化
├── scripts/
│   ├── install.ps1             # 智能安装与自动提权脚本
│   └── restore.ps1             # 安全备份恢复脚本
└── tools/
    ├── asar.js                 # 零外部依赖的独立 ASAR 打包/解包引擎
    └── apply-patches.js        # 自动化解包、补丁合并与重新打包工具
```

---

## 📋 翻译覆盖范围清单

| 模块区域 | 汉化覆盖范围 | 状态 |
| :--- | :--- | :---: |
| **左侧导航栏** | 新建对话、对话历史、自动化任务、项目切换、技能与自定义、系统设置 | ✅ 100% |
| **对话主画布** | 思考状态、工作计时、工具调用结果、代码块操作、历史回滚、底部占位符 | ✅ 100% |
| **输入框与交互** | 占位提示语（随时提问，输入 @ 引用...）、自动补全弹窗、附件与语音入口 | ✅ 100% |
| **快捷键与命令** | `/` 斜杠命令列表与说明、`@` 上下文提及菜单、全局快捷键清单 | ✅ 100% |
| **模型与用量** | 模型选择器（Gemini/Claude/GPT）、思考强度（高/中/低）、配额与用量说明 | ✅ 100% |
| **应用设置面板** | 通用设置、外观主题、模型配额、通知偏好、权限控制、开发者选项、反馈对话框 | ✅ 100% |
| **系统原生层** | Windows 系统托盘菜单、窗口顶部菜单、退出确认对话框、自动更新提示 | ✅ 100% |

---

## 🤝 参与贡献

欢迎对汉化表达提出优化建议或补充新增词条：
1. Fork 本仓库
2. 在 `src/zh-cn-translate.js` 的 `TRANSLATIONS` 字典或 `PATTERN_TRANSLATIONS` 正则数组中修改或添加条目
3. 提交 PR 并简要说明修改内容

---

## ⚠️ 免责声明

- 本项目为开源社区维护的**非官方**本地化补丁，与 Google 官方无关。
- 安装程序默认自动备份原始文件，安全无侵入；应用版本更新后只需重新双击运行【一键安装汉化.bat】即可重新生效。
- 遵循 MIT 开源许可证。
