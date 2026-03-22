#!/bin/bash
set -euo pipefail

# ─── Configuration ───
APP_NAME="Slipnet-macOS"
PKG_NAME="Slipnet-macOS-Installer"
VERSION="1.2.0"
IDENTIFIER="com.amirhp.SlipnetMacOS"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
PKG_ROOT="${BUILD_DIR}/pkg-root"
PKG_OUTPUT="${PROJECT_DIR}/${PKG_NAME}.pkg"

echo "=== Building ${APP_NAME} v${VERSION} ==="

# ─── Step 1: Build the app (Release, Universal Binary) ───
echo "[1/5] Building app with xcodebuild..."
xcodebuild -project "${PROJECT_DIR}/BlackSwan.xcodeproj" \
    -scheme "Slipnet-macOS" \
    -configuration Release \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    archive \
    ONLY_ACTIVE_ARCH=NO \
    2>&1 | tail -5

# Export the archive
echo "[2/5] Exporting archive..."
cat > "${BUILD_DIR}/ExportOptions.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
PLIST

APP_PATH=""
if xcodebuild -exportArchive \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    -exportOptionsPlist "${BUILD_DIR}/ExportOptions.plist" \
    -exportPath "${BUILD_DIR}/export" 2>/dev/null; then
    APP_PATH="${BUILD_DIR}/export/${APP_NAME}.app"
else
    echo "  (Using archive app directly — no Developer ID signing)"
    APP_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive/Products/Applications/${APP_NAME}.app"
fi

if [ ! -d "${APP_PATH}" ]; then
    echo "ERROR: Built app not found at ${APP_PATH}"
    find "${BUILD_DIR}" -name "*.app" -maxdepth 5 2>/dev/null
    exit 1
fi

echo "  App built at: ${APP_PATH}"

# ─── Step 3: Copy .app to project root ───
echo "[3/5] Copying app to project root..."
rm -rf "${PROJECT_DIR}/${APP_NAME}.app"
cp -R "${APP_PATH}" "${PROJECT_DIR}/${APP_NAME}.app"

# ─── Step 4: Prepare pkg payload ───
echo "[4/5] Preparing installer payload..."
rm -rf "${PKG_ROOT}"
mkdir -p "${PKG_ROOT}/Applications"
cp -R "${APP_PATH}" "${PKG_ROOT}/Applications/${APP_NAME}.app"

# ─── Step 5: Build the .pkg installer ───
echo "[5/5] Building installer package..."
pkgbuild \
    --root "${PKG_ROOT}" \
    --identifier "${IDENTIFIER}" \
    --version "${VERSION}" \
    --install-location "/" \
    "${PKG_OUTPUT}"

echo ""
echo "=== Done ==="
echo "App:       ${PROJECT_DIR}/${APP_NAME}.app"
echo "Installer: ${PKG_OUTPUT}"
echo "Size:      $(du -h "${PKG_OUTPUT}" | cut -f1)"
