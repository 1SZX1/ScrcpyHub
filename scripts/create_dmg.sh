#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ScrcpyHub"
APP_BUNDLE="${PROJECT_DIR}/${APP_NAME}.app"
DIST_DIR="${PROJECT_DIR}/dist"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-macOS-arm64.dmg"
ZIP_NAME="${APP_NAME}-macOS-arm64.zip"

echo "=========================================="
echo "📦 开始制作 ${APP_NAME} 发布包 (DMG & ZIP)"
echo "=========================================="

# 1. 确保先完成 App 构建
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "⚠️ 未发现已编译的 ${APP_NAME}.app，正在执行构建..."
    bash "${PROJECT_DIR}/scripts/build_app.sh"
fi

# 2. 准备输出目录
mkdir -p "${DIST_DIR}"
rm -f "${DIST_DIR}/${DMG_NAME}" "${DIST_DIR}/${ZIP_NAME}"

# 3. 创建临时 staging 目录
STAGING_DIR="/tmp/${APP_NAME}_dmg_staging"
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"

echo "📥 正在准备 DMG 安装内容..."
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"

# 创建 Applications 快捷替身软链接
ln -s /Applications "${STAGING_DIR}/Applications"

# 4. 生成 DMG
echo "💿 正在生成 DMG 镜像 (${DMG_NAME})..."
TMP_DMG="/tmp/${APP_NAME}_temp.dmg"
rm -f "${TMP_DMG}"

hdiutil create -srcfolder "${STAGING_DIR}" \
               -volname "${APP_NAME}" \
               -fs HFS+ \
               -fsargs "-c c=64,a=16,e=16" \
               -format UDRW \
               -size 150m \
               "${TMP_DMG}" >/dev/null

# 压缩为最终分发 DMG
hdiutil convert "${TMP_DMG}" \
                -format UDBZ \
                -imagekey zlib-level=9 \
                -o "${DIST_DIR}/${DMG_NAME}" >/dev/null

rm -f "${TMP_DMG}"
rm -rf "${STAGING_DIR}"

# 5. 生成标准 ZIP 压缩包 (使用 ditto 保留 macOS 代码签名与权限)
echo "🗜️ 正在生成 ZIP 发布包 (${ZIP_NAME})..."
cd "${PROJECT_DIR}"
ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "${DIST_DIR}/${ZIP_NAME}"

echo "=========================================="
echo "🎉 发布包制作完成！"
echo "DMG 路径: ${DIST_DIR}/${DMG_NAME} ($(du -h "${DIST_DIR}/${DMG_NAME}" | cut -f1))"
echo "ZIP 路径: ${DIST_DIR}/${ZIP_NAME} ($(du -h "${DIST_DIR}/${ZIP_NAME}" | cut -f1))"
echo "SHA256 (DMG): $(shasum -a 256 "${DIST_DIR}/${DMG_NAME}" | cut -d' ' -f1)"
echo "SHA256 (ZIP): $(shasum -a 256 "${DIST_DIR}/${ZIP_NAME}" | cut -d' ' -f1)"
echo "=========================================="
