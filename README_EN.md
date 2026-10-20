# ScrcpyHub

<p align="center">
  <img src="docs/assets/icon.png" width="128" height="128" alt="ScrcpyHub Icon" />
</p>

<p align="center">
  <b>A modern, high-performance macOS native GUI client for scrcpy & multi-device manager</b>
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

## ✨ Features

- 🍎 **Native macOS Experience**: Built with SwiftUI & AppKit. Instant startup, ultra-low resource usage, and seamless Light/Dark mode support.
- 🖥️ **Dual-Mode Interaction**:
  - **Main Console**: Visual device manager with real-time battery status, native resolution display, and granular audiovisual settings.
  - **Menu Bar Extra**: Stays in the system menu bar for quick device overview and one-click mirroring.
- 🎮 **Floating Companion HUD**:
  - **Key Simulation**: Back, Home, App Switcher, Volume Up/Down, Screen On/Off, and Notification shade.
  - **Drag-and-Drop**: Drag `.apk` files to install automatically, or drop any files to transfer directly to the device.
  - **Lossless Screenshots**: One-click capture saved directly to the Mac Downloads folder.
- ⚡ **Wireless ADB & Multi-Device Concurrency**:
  - One-click wireless transition while plugged in, plus Android 11+ pairing code support for true cable-free setup.
  - Concurrent mirroring for multiple Android devices with independent configurations.
- 🎯 **Preset Profiles & Defaults**:
  - Built-in scenarios: Low-latency Gaming, Ultra HD, Stealth (Screen-off), and Wi-Fi Anti-jitter.
  - Save customized configurations as personal presets or set them as global defaults.
- 📦 **Zero-Config Battery Included**: Embedded with official **scrcpy 5.0.1** and **ADB 37.0.1** binaries. No Homebrew or CLI setup required.

---

## 📥 Download & Installation

Download the latest **`ScrcpyHub-macOS-arm64.dmg`** from [**GitHub Releases**](https://github.com/):

1. Open the downloaded `.dmg` image;
2. Drag **ScrcpyHub** into your **Applications** folder.

> **Requirements**: macOS 13.0 (Ventura) or later, Apple Silicon (M1 / M2 / M3 / M4).

---

## 🚀 Quick Start

1. Enable **Settings ➔ Developer Options ➔ USB Debugging** on your phone;
2. Connect your device via USB cable (or pair wirelessly);
3. Launch ScrcpyHub and click **"Start Mirroring"**.

---

## 🛠️ Build from Source

To build or contribute locally:

```bash
# 1. Clone this repository
git clone https://github.com/<your-username>/ScrcpyHub.git
cd ScrcpyHub

# 2. Compile and package DMG & ZIP (auto-downloads tools and builds Swift binary)
./scripts/create_dmg.sh
```

Distribution packages will be generated in `dist/`. You can also open `App/Package.swift` directly in **Xcode** for development.

---

## 📄 License

This project is licensed under the [Apache License 2.0](LICENSE).

### Acknowledgments
- [Genymobile/scrcpy](https://github.com/Genymobile/scrcpy): The remarkable Android display and control engine
- [Google Android Platform Tools](https://developer.android.com/studio/releases/platform-tools): ADB (Android Debug Bridge)
