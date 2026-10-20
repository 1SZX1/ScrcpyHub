# ScrcpyHub - macOS 原生可视化投屏与设备管理中心

<p align="center">
  <img src="docs/assets/icon.png" width="128" height="128" alt="ScrcpyHub Icon" />
</p>

<p align="center">
  <b>基于 Swift 6 + SwiftUI + AppKit 构建的 macOS 原生高性能 scrcpy 图形化投屏与多设备管理桌面软件</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013.0+-black?logo=apple" alt="Platform" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20(arm64)-orange" alt="Architecture" />
  <img src="https://img.shields.io/badge/Swift-6.0-red?logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/scrcpy-5.0.1-brightgreen" alt="scrcpy" />
  <img src="https://img.shields.io/badge/License-Apache%202.0-blue" alt="License" />
</p>

<p align="center">
  <b><a href="README.md">简体中文</a></b> | <a href="README_EN.md">English</a>
</p>

---

## 🌟 核心特性

- **🍎 纯正 macOS 原生体验**：采用 SwiftUI + AppKit 开发，毫秒级冷启动、极致低内存占用，深度适配 macOS 浅色/深色主题。
- **🖥️ 双模态协同交互**：
  - **主控制台**：直观管理设备池、实时显示电池与充电状态、原生分辨率、精细调节视音频画质与行为。
  - **系统菜单栏常驻 (Menu Bar Extra)**：常驻屏幕顶部菜单栏，随时查看在线设备，一键快速投屏。
- **🎮 智能伴随悬浮操作栏 (Floating HUD Dock)**：
  - **Android 物理按键模拟**：返回键 (Back)、主页 (Home)、多任务 (Recents)、音量加减、电源/锁屏、下拉通知栏。
  - **无损截屏与录屏**：一键捕获手机屏幕高清截屏并自动定位在访达下载目录。
  - **拖拽安装与直传**：支持拖入 `.apk` 文件一键自动静默安装，拖入任意文件直接推送至手机下载目录。
  - **原生平滑拖拽**：基于 AppKit `window.performDrag` 抓手，随心拖动吸附于屏幕任意位置。
- **⚡ 多设备并发与一键无线 ADB**：
  - USB 自动拔插侦测与心跳监听，永久缓存识别商业市场机型名（如 `Xiaomi 15`），杜绝刷新闪烁。
  - **一键无线投屏**：插线状态下一键开启 TCP/IP 模式并自动连接局域网 IP，即刻拔线无线畅玩。
  - **Android 11+ 六位配对码配对**：纯无线免插线秒级配对，配对一次终身有效；支持传统 IP 端口直连。
  - **常驻无线添加入口**：即使已有设备连接，设备列表底部始终常驻「+ 连接新无线设备」入口，随时接入新设备。
  - 支持多台 Android 设备独立配置、并发多开投屏。
- **🎯 自定义预设方案 (Custom Presets)**：
  - 内置 5 大场景预设（均衡流畅、极限电竞、超清演示、息屏摸鱼、无线抗抖）。
  - 支持将任意画质与行为参数**一键保存为自定义预设**，支持专属图标与名称，本地自动 JSON 持久化。
  - **自适应弹性网格**：根据窗口宽度自动折行排布卡片，窗口拉窄拉宽均完整显示，彻底告别横滚困扰。
- **🚀 最新底层工具内核**：内嵌官方最新 **scrcpy 5.0.1** (SDL 3.4.18 + libavcodec 63) 与 **ADB 37.0.1**。

---

## 📁 目录组织架构

本项目遵循现代模块化分层规范，源码与二进制资产完全解耦，适合长期维护与 Git 仓库协同：

```
.
├── .github/                         # GitHub Actions CI/CD 自动化流水线
│   └── workflows/
│       └── release.yml              # 自动编译与 Release DMG/ZIP 发布配置
├── App/                             # Swift 6 原生桌面应用工程源码
│   ├── Package.swift                # SPM 依赖管理配置
│   ├── Sources/                     # 源代码目录
│   │   └── ScrcpyHub/
│   │       ├── AppMain.swift        # App 主入口与双模态场景
│   │       ├── Models/              # 数据模型 (Device, Config, Presets)
│   │       ├── Services/            # 核心业务 (ADB, Process, PresetStore)
│   │       ├── Views/               # SwiftUI 界面组件与悬浮条
│   │       └── Utils/               # 智能路径解析与通用工具
│   └── Resources/                   # 应用资源 (AppIcon, Info.plist)
├── bin/                             # 底层 scrcpy & adb 工具包 (由脚本自动下载，Git 忽略)
│   └── .gitkeep
├── docs/                            # 项目文档与多媒体资源
│   └── assets/                      # 图标及演示配图
├── scripts/                         # 自动化运维脚本
│   ├── setup_binaries.sh            # 自动拉取官方 scrcpy 5.0.1 工具包
│   ├── build_app.sh                 # 一键编译并打包生成独立 ScrcpyHub.app
│   └── create_dmg.sh                # 自动打包生成 DMG 安装镜像与 ZIP 发布包
├── .gitignore                       # 规范的 Git 忽略规则
├── LICENSE                          # Apache 2.0 开源许可证
├── README.md                        # 中文项目说明文档
└── README_EN.md                     # 英文项目说明文档
```

---

## 🛠️ 快速开始

### 系统运行要求
- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon 架构 (M1 / M2 / M3 / M4 系列芯片)
- 手机端：开启【开发者选项 -> USB 调试】（无线投屏需手机与 Mac 连接同一局域网）

### 方式一：直接下载安装包 (推荐)
直接前往 [GitHub Releases](https://github.com/) 页面下载最新版 **`ScrcpyHub-macOS-arm64.dmg`**，双击打开并将 `ScrcpyHub.app` 拖入 `Applications`（应用程序）文件夹即可开箱即用。

### 方式二：从源码一键构建
克隆仓库到本地后，在根目录直接执行：

```bash
# 自动下载底层工具、编译 Swift 源码并生成 DMG 安装镜像与 ZIP 包
./scripts/create_dmg.sh
```

构建成功后，将在 `dist/` 目录和项目根目录下生成开箱即用的 **`ScrcpyHub-macOS-arm64.dmg`** 与 **`ScrcpyHub.app`**（已自带本地 Ad-hoc 代码签名）。

### 2. 启动与使用
- 双击根目录下的 **`ScrcpyHub.app`** 或将其拖移至 `/Applications`（访达“应用程序”）目录。
- 使用 USB 连接手机，应用秒级识别设备并展示电量与状态。
- 选择预设场景或自定义参数后，点击「**立即启动投屏**」即可！

---

## 🧑‍💻 开发与调试

如果您需要进行二次开发或界面调整：

1. **命令行直接编译调试**：
   ```bash
   cd App
   swift run
   ```

2. **使用 Xcode 打开**：
   双击 `App/Package.swift` 或在根目录执行：
   ```bash
   xed App
   ```
   在 Xcode 中即可享受完整的代码补全、预览 (Canvas) 与断点调试。

3. **重新打包发布**：
   ```bash
   ./scripts/build_app.sh
   ```

---

## 📄 开源许可证

本项目基于 [Apache License 2.0](LICENSE) 开源。

### 鸣谢
- [Genymobile/scrcpy](https://github.com/Genymobile/scrcpy)：卓越的 Android 极速投屏引擎
- [Google Android Platform Tools](https://developer.android.com/studio/releases/platform-tools)：强大的 ADB 调试桥
