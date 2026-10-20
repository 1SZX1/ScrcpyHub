#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ScrcpyHub"
APP_DIR="${PROJECT_DIR}/App"
BIN_DIR="${PROJECT_DIR}/bin"
OUTPUT_BUNDLE="${PROJECT_DIR}/${APP_NAME}.app"
BUILD_DIR="${APP_DIR}/.build/release"
ICON_SOURCE="${PROJECT_DIR}/docs/assets/icon.png"

echo "=========================================="
echo "🚀 开始构建 ${APP_NAME}.app (macOS Apple Silicon)"
echo "=========================================="

# 1. 确保底层工具包完备
if [ ! -f "${BIN_DIR}/scrcpy" ] || [ ! -f "${BIN_DIR}/adb" ] || [ ! -f "${BIN_DIR}/scrcpy-server" ]; then
    echo "⚠️ 检测到缺少底层二进制工具，正在自动执行初始化..."
    bash "${PROJECT_DIR}/scripts/setup_binaries.sh"
fi

# 2. 编译 Swift Release 二进制
echo "📦 正在编译 Swift 原生 Release 二进制..."
cd "${APP_DIR}"
swift build -c release

# 3. 清理旧 App 目录
echo "🧹 清理旧应用包..."
rm -rf "${OUTPUT_BUNDLE}"

# 4. 创建 macOS App Bundle 目录结构
echo "📁 创建 App Bundle 结构..."
mkdir -p "${OUTPUT_BUNDLE}/Contents/MacOS"
mkdir -p "${OUTPUT_BUNDLE}/Contents/Resources/bin"

# 5. 拷贝主程序
echo "📥 拷贝主程序可执行文件..."
cp "${BUILD_DIR}/ScrcpyHub" "${OUTPUT_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${OUTPUT_BUNDLE}/Contents/MacOS/${APP_NAME}"

# 6. 嵌入 scrcpy 与 adb 工具集
echo "📥 嵌入原生 scrcpy 与 adb 工具集..."
cp "${BIN_DIR}/adb" "${OUTPUT_BUNDLE}/Contents/Resources/bin/adb"
cp "${BIN_DIR}/scrcpy" "${OUTPUT_BUNDLE}/Contents/Resources/bin/scrcpy"
cp "${BIN_DIR}/scrcpy-server" "${OUTPUT_BUNDLE}/Contents/Resources/bin/scrcpy-server"
chmod +x "${OUTPUT_BUNDLE}/Contents/Resources/bin/adb"
chmod +x "${OUTPUT_BUNDLE}/Contents/Resources/bin/scrcpy"

# 在 Resources 根目录下保留一份 scrcpy-server 副本兼容
cp "${BIN_DIR}/scrcpy-server" "${OUTPUT_BUNDLE}/Contents/Resources/scrcpy-server"

# 7. 生成应用图标 AppIcon.icns
echo "🎨 生成应用图标..."
ICONSET_DIR="/tmp/ScrcpyHub_Icon.iconset"
rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"

if [ -f "${ICON_SOURCE}" ]; then
    sips -z 16 16     "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_16x16.png" >/dev/null 2>&1 || true
    sips -z 32 32     "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_16x16@2x.png" >/dev/null 2>&1 || true
    sips -z 32 32     "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_32x32.png" >/dev/null 2>&1 || true
    sips -z 64 64     "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_32x32@2x.png" >/dev/null 2>&1 || true
    sips -z 128 128   "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_128x128.png" >/dev/null 2>&1 || true
    sips -z 256 256   "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_128x128@2x.png" >/dev/null 2>&1 || true
    sips -z 256 256   "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_256x256.png" >/dev/null 2>&1 || true
    iconutil -c icns "${ICONSET_DIR}" -o "${OUTPUT_BUNDLE}/Contents/Resources/AppIcon.icns"
    rm -rf "${ICONSET_DIR}"
fi

# 8. 写入 Info.plist
echo "📝 写入 Info.plist..."
cat << 'EOF' > "${OUTPUT_BUNDLE}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>ScrcpyHub</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.scrcpy.hub</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>ScrcpyHub</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
EOF

# 9. 进行本地自签名 (防止 macOS 拦截)
echo "🔏 执行本地 Ad-hoc 代码签名..."
codesign --force --deep --sign - "${OUTPUT_BUNDLE}"

echo "=========================================="
echo "🎉 构建打包完成！"
echo "应用路径: ${OUTPUT_BUNDLE}"
echo "您可以直接双击运行，或拖移至 /Applications 目录"
echo "=========================================="
