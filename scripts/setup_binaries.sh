#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="${PROJECT_DIR}/bin"
SCRCPY_VERSION="v5.0.1"
DOWNLOAD_URL="https://github.com/Genymobile/scrcpy/releases/download/${SCRCPY_VERSION}/scrcpy-macos-aarch64-${SCRCPY_VERSION}.tar.gz"

echo "=========================================="
echo "📥 检查并配置 scrcpy & adb 工具包"
echo "=========================================="

mkdir -p "${BIN_DIR}"

if [ -f "${BIN_DIR}/scrcpy" ] && [ -f "${BIN_DIR}/adb" ] && [ -f "${BIN_DIR}/scrcpy-server" ]; then
    echo "✅ bin/ 目录下已存在所需工具，跳过下载。"
    echo "当前 scrcpy 版本: $("${BIN_DIR}/scrcpy" --version | head -n 1)"
    echo "当前 adb 版本: $("${BIN_DIR}/adb" version | head -n 1)"
    exit 0
fi

echo "🌐 正在从 GitHub 官方下载 scrcpy ${SCRCPY_VERSION} (Apple Silicon)..."
TMP_ARCHIVE="/tmp/scrcpy-${SCRCPY_VERSION}.tar.gz"
TMP_DIR="/tmp/scrcpy-unpack"

curl -L -o "${TMP_ARCHIVE}" "${DOWNLOAD_URL}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"
tar -xzf "${TMP_ARCHIVE}" -C "${TMP_DIR}"

EXTRACTED_DIR=$(find "${TMP_DIR}" -type d -name "scrcpy-macos-aarch64*" | head -n 1)

if [ -z "${EXTRACTED_DIR}" ]; then
    echo "❌ 解压失败，未找到解压目录！"
    exit 1
fi

echo "📦 正在部署二进制文件至 ${BIN_DIR}..."
cp "${EXTRACTED_DIR}/adb" "${BIN_DIR}/"
cp "${EXTRACTED_DIR}/scrcpy" "${BIN_DIR}/"
cp "${EXTRACTED_DIR}/scrcpy-server" "${BIN_DIR}/"
[ -f "${EXTRACTED_DIR}/scrcpy.1" ] && cp "${EXTRACTED_DIR}/scrcpy.1" "${BIN_DIR}/"

chmod +x "${BIN_DIR}/adb"
chmod +x "${BIN_DIR}/scrcpy"

# 清理临时文件
rm -rf "${TMP_ARCHIVE}" "${TMP_DIR}"

echo "=========================================="
echo "🎉 工具包部署完成！"
echo "scrcpy: $("${BIN_DIR}/scrcpy" --version | head -n 1)"
echo "adb: $("${BIN_DIR}/adb" version | head -n 1)"
echo "=========================================="
