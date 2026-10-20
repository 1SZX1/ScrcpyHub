# ScrcpyHub - macOS Native Screen Mirroring & Multi-Device Manager

<p align="center">
  <img src="docs/assets/icon.png" width="128" height="128" alt="ScrcpyHub Icon" />
</p>

<p align="center">
  <b>A modern, high-performance macOS native desktop client for scrcpy built with Swift 6 + SwiftUI + AppKit</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013.0+-black?logo=apple" alt="Platform" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20(arm64)-orange" alt="Architecture" />
  <img src="https://img.shields.io/badge/Swift-6.0-red?logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/scrcpy-5.0.1-brightgreen" alt="scrcpy" />
  <img src="https://img.shields.io/badge/License-Apache%202.0-blue" alt="License" />
</p>

<p align="center">
  <a href="README.md">简体中文</a> | <b><a href="README_EN.md">English</a></b>
</p>

---

## 🌟 Key Features

- **🍎 Pure Native macOS Experience**: Crafted with SwiftUI & AppKit. Sub-second cold startup, extremely low memory footprint, and seamless macOS Light / Dark mode support.
- **🖥️ Dual-Mode Interaction**:
  - **Main Console**: Effortlessly manage device pools, view real-time battery status, native resolutions, and fine-tune audiovisual quality and system behaviors.
  - **Menu Bar Extra**: Stays in the macOS system menu bar for instant device overview and one-click quick mirroring.
- **🎮 Floating Quick-Control HUD**:
  - **Hardware Key Simulation**: Back, Home, App Switcher (Recents), Volume Up/Down, Power / Lock, and Expand Notification Shade.
  - **Lossless Screenshots**: One-click screen capture directly saved to macOS Downloads and highlighted in Finder.
  - **Drag-and-Drop Installation & Transfer**: Drop `.apk` files to install automatically, or drop any files to transfer directly to the device's Download folder.
  - **Smooth Native Dragging**: Window-level dragging handle powered by AppKit `window.performDrag`.
- **⚡ Multi-Device Concurrency & Wireless ADB**:
  - Auto-detection for USB hot-plugging with heartbeat listeners. Caches commercial market device names (e.g., `Xiaomi 15`) to eliminate flicker.
  - **One-Click Wireless**: Switch to TCP/IP and auto-connect device IP while plugged in, then unplug cable to enjoy wireless mirroring.
  - **Android 11+ 6-Digit Pairing Wizard**: True wireless pairing without requiring USB cables. Pair once and connect anytime.
  - **Always-Present Wireless Entry**: Quick add-device action at the bottom of the device list even when devices are already connected.
  - Supports concurrent multi-window mirroring with independent configs.
- **🎯 Custom Preset Profiles**:
  - 5 built-in presets: Balanced (Default), Ultra Low Latency (Gaming), Ultra HD (Presentation), Stealth (Screen-off), and Wi-Fi Anti-Jitter.
  - Save any customized parameters as custom profiles with customized icons and titles, persistently stored in local JSON.
  - **Adaptive Grid Layout**: Responsive card arrangement that wraps smoothly without horizontal scrollbars.
- **🚀 Built with the Latest Core Engines**: Bundled with official **scrcpy 5.0.1** (SDL 3.4.18 + libavcodec 63) and **ADB 37.0.1**.

---

## 📁 Repository Structure

The project follows a clean, decoupled modular architecture. Binary dependencies and build artifacts are separated from the Swift source code:

```
.
├── .github/                         # GitHub Actions CI/CD workflows
│   └── workflows/
│       └── release.yml              # Automated build & release pipeline
├── App/                             # Swift 6 desktop application source (SPM)
│   ├── Package.swift                # SPM dependency configuration
│   ├── Sources/                     # App logic (Models, Services, Views, Utils)
│   └── Resources/                   # App assets (Info.plist, icon.png)
├── bin/                             # Bundled scrcpy & adb binaries (git-ignored)
│   └── .gitkeep
├── docs/                            # Documentation and assets
│   └── assets/                      # Icon and preview graphics
├── scripts/                         # Automation maintenance scripts
│   ├── setup_binaries.sh            # Auto-download scrcpy 5.0.1 release
│   ├── build_app.sh                 # Compile & assemble ScrcpyHub.app
│   └── create_dmg.sh                # Generate distribution DMG & ZIP
├── .gitignore                       # Clean Git ignore rules
├── LICENSE                          # Apache 2.0 License
├── README.md                        # Documentation in Simplified Chinese
└── README_EN.md                     # Documentation in English
```

---

## 🛠️ Quick Start

### System Requirements
- macOS 13.0 (Ventura) or later
- Apple Silicon (M1 / M2 / M3 / M4 family chips)
- Android device: Enable **Developer Options > USB Debugging** (For wireless, connect to the same Wi-Fi)

### Option 1: Download Pre-built Release (Recommended)
Download the latest **`ScrcpyHub-macOS-arm64.dmg`** from the [GitHub Releases](https://github.com/) page, open it, and drag `ScrcpyHub.app` into your `Applications` folder.

### Option 2: Build from Source
Clone the repository and run the build script in the root directory:

```bash
# Clone the repository
git clone <your-repo-url>
cd ScrcpyHub

# Build DMG and ZIP distribution packages (auto-downloads tools and compiles Swift)
./scripts/create_dmg.sh
```

The compiled **`ScrcpyHub.app`** and DMG image will be ready under `dist/` and the project root.

---

## 🧑‍💻 Development

If you wish to customize features or develop locally:

1. **Run directly from terminal**:
   ```bash
   cd App
   swift run
   ```

2. **Open with Xcode**:
   Double click `App/Package.swift` or run:
   ```bash
   xed App
   ```
   Enjoy Swift code completion, SwiftUI Canvas previews, and debugging.

3. **Re-package release**:
   ```bash
   ./scripts/create_dmg.sh
   ```

---

## 📄 License

This project is licensed under the [Apache License 2.0](LICENSE).

### Acknowledgments
- [Genymobile/scrcpy](https://github.com/Genymobile/scrcpy): The incredible low-latency Android display and control engine
- [Google Android Platform Tools](https://developer.android.com/studio/releases/platform-tools): Android Debug Bridge (ADB)
