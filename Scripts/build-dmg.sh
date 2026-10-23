#!/bin/bash
#
# Build Maxgus World Clock without Xcode and package it as a DMG.
#
# Requirements: macOS 14+, Command Line Tools (swiftc, lipo, codesign,
# iconutil, hdiutil). Run from anywhere:
#
#   ./Scripts/build-dmg.sh
#
# The app is ad-hoc signed by default. Set CODESIGN_IDENTITY to use a
# Developer ID for distribution:
#
#   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
#     ./Scripts/build-dmg.sh
#
set -euo pipefail

# Prefer the Command Line Tools. If Xcode is installed but its license has not
# been accepted, xcrun would otherwise refuse to run swiftc. Override
# DEVELOPER_DIR explicitly if you want to build with a different toolchain.
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d "/Library/Developer/CommandLineTools" ]; then
    export DEVELOPER_DIR="/Library/Developer/CommandLineTools"
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Maxgus World Clock"
APP_BUNDLE_ID="com.maxgus.worldclock"
WIDGET_BUNDLE_ID="${APP_BUNDLE_ID}.widget"
VERSION="1.0"
BUILD_NUMBER="2"
MIN_MACOS="14.0"
ARCHS="${ARCHS:-arm64 x86_64}"
IDENTITY="${CODESIGN_IDENTITY:--}"

BUILD_ROOT="${ROOT}/build/installer"
BIN_ROOT="${BUILD_ROOT}/bin"
STAGE="${BUILD_ROOT}/dmg"
APP="${STAGE}/${APP_NAME}.app"
APPEX="${APP}/Contents/PlugIns/WorldClockWidget.appex"
DIST="${ROOT}/dist"
SDK="$(xcrun --show-sdk-path)"
MODULE_CACHE="${BUILD_ROOT}/module-cache"

# The Command Line Tools and the full Xcode ship their own SDKs, and a
# half-updated install pairs a newer compiler with an older SDK. Swift then
# refuses to build anything ("this SDK is not supported by the compiler").
# Fail early with an actionable message instead of a wall of compiler output.
check_toolchain() {
    local probe="${BUILD_ROOT}/probe.swift"
    mkdir -p "${BUILD_ROOT}"
    printf 'let x = 1\n' > "${probe}"
    if ! xcrun swiftc -typecheck -sdk "${SDK}" \
        -module-cache-path "${MODULE_CACHE}" "${probe}" >/dev/null 2>&1; then
        echo "error: the Swift toolchain at ${DEVELOPER_DIR:-$(xcode-select -p)}" >&2
        echo "       cannot build against its own SDK." >&2
        echo "       Fix it by pointing DEVELOPER_DIR at the full Xcode:" >&2
        echo "         DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer $0" >&2
        echo "       or by updating the Command Line Tools in Software Update." >&2
        exit 1
    fi
    rm -f "${probe}"
}

echo "==> Building ${APP_NAME} ${VERSION} for: ${ARCHS}"
rm -rf "${BUILD_ROOT}"
mkdir -p "${BIN_ROOT}" "${APP}/Contents/MacOS" "${APP}/Contents/Resources" \
    "${APP}/Contents/PlugIns" "${APPEX}/Contents/MacOS" \
    "${APPEX}/Contents/Resources" "${DIST}" "${MODULE_CACHE}"

check_toolchain

# Compile one binary per architecture, then combine with lipo.
for ARCH in ${ARCHS}; do
    case "${ARCH}" in
        arm64)  TARGET="arm64-apple-macosx${MIN_MACOS}" ;;
        x86_64) TARGET="x86_64-apple-macosx${MIN_MACOS}" ;;
        *)
            echo "Unsupported architecture: ${ARCH}" >&2
            exit 1
            ;;
    esac

    mkdir -p "${BIN_ROOT}/${ARCH}"

    echo "    app ${ARCH}"
    xcrun swiftc -O -parse-as-library -sdk "${SDK}" -target "${TARGET}" \
        -swift-version 5 -module-cache-path "${MODULE_CACHE}" \
        "${ROOT}/Shared/"*.swift "${ROOT}/MaxgusWorldClock/"*.swift \
        -o "${BIN_ROOT}/${ARCH}/MaxgusWorldClock" \
        -framework SwiftUI -framework AppKit -framework AppIntents -framework WidgetKit

    echo "    widget ${ARCH}"
    xcrun swiftc -O -parse-as-library -application-extension \
        -sdk "${SDK}" -target "${TARGET}" -swift-version 5 \
        -module-cache-path "${MODULE_CACHE}" \
        "${ROOT}/Shared/"*.swift "${ROOT}/WorldClockWidget/"*.swift \
        -o "${BIN_ROOT}/${ARCH}/WorldClockWidget" \
        -framework WidgetKit -framework SwiftUI -framework AppIntents \
        -framework Foundation -framework AppKit \
        -Xlinker -e -Xlinker _NSExtensionMain
done

lipo -create "${BIN_ROOT}/"*/MaxgusWorldClock \
    -output "${APP}/Contents/MacOS/MaxgusWorldClock"
lipo -create "${BIN_ROOT}/"*/WorldClockWidget \
    -output "${APPEX}/Contents/MacOS/WorldClockWidget"
chmod +x "${APP}/Contents/MacOS/MaxgusWorldClock" \
    "${APPEX}/Contents/MacOS/WorldClockWidget"

# Icon
ICONSET="${BUILD_ROOT}/AppIcon.iconset"
mkdir -p "${ICONSET}"
cp "${ROOT}/MaxgusWorldClock/Assets.xcassets/AppIcon.appiconset/"*.png "${ICONSET}/"
iconutil -c icns "${ICONSET}" -o "${APP}/Contents/Resources/AppIcon.icns"

# Bundle metadata
cat > "${APP}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
    <key>CFBundleExecutable</key><string>MaxgusWorldClock</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIdentifier</key><string>${APP_BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>${APP_NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
    <key>CFBundleSupportedPlatforms</key><array><string>MacOSX</string></array>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key><string>${MIN_MACOS}</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSHumanReadableCopyright</key><string>© 2026 Maxgus</string>
</dict>
</plist>
PLIST

cat > "${APPEX}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
    <key>CFBundleExecutable</key><string>WorldClockWidget</string>
    <key>CFBundleIdentifier</key><string>${WIDGET_BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>WorldClockWidget</string>
    <key>CFBundlePackageType</key><string>XPC!</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
    <key>CFBundleSupportedPlatforms</key><array><string>MacOSX</string></array>
    <key>LSMinimumSystemVersion</key><string>${MIN_MACOS}</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
    <key>originalAppBundleIdentifier</key><string>${APP_BUNDLE_ID}</string>
</dict>
</plist>
PLIST

printf 'APPL????' > "${APP}/Contents/PkgInfo"
printf 'XPC!????' > "${APPEX}/Contents/PkgInfo"

# Xcode normally runs appintentsmetadataprocessor as part of the widget build.
# The extracted metadata is checked in so this script stays Xcode-free. If the
# intent, CityEntity, or CityQuery changes, regenerate it with:
#
#   ./Scripts/generate-appintents-metadata.sh
cp -R "${ROOT}/Scripts/AppIntentsMetadata" \
    "${APPEX}/Contents/Resources/Metadata.appintents"
python3 -m json.tool \
    "${APPEX}/Contents/Resources/Metadata.appintents/extract.actionsdata" \
    >/dev/null
python3 -m json.tool \
    "${APPEX}/Contents/Resources/Metadata.appintents/version.json" \
    >/dev/null
plutil -lint "${APP}/Contents/Info.plist" "${APPEX}/Contents/Info.plist" >/dev/null

# Minimal sandbox entitlements.
#
# No app group is requested here on purpose. An application group identifier
# only resolves to a shared container when the binary is signed with a Team ID
# and a provisioning profile that carries the matching
# com.apple.security.application-groups entitlement. This script signs
# ad-hoc ("-"), so the entitlement would be dropped during signing and the
# group container would be created but never be writable -- reads and writes
# would silently fall back to each process' private container instead.
#
# That is fine for the current design: every widget placement keeps its own
# city configuration in its own AppIntents storage, and the app and the
# widget never need to exchange data at runtime. Shared/../RosterStore
# detects the missing group and degrades to .standard UserDefaults.
#
# To ship with a real app group, sign with a Developer ID + provisioning
# profile and pass the entitlements checked in at:
#   MaxgusWorldClock/MaxgusWorldClock.entitlements
#   WorldClockWidget/WorldClockWidget.entitlements
# e.g. CODESIGN_IDENTITY="Developer ID Application: ..." APP_GROUP=group.com.maxgus.worldclock
cat > "${BUILD_ROOT}/app.entitlements" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key><true/>
</dict>
</plist>
PLIST
cp "${BUILD_ROOT}/app.entitlements" "${BUILD_ROOT}/widget.entitlements"

if [ -n "${APP_GROUP:-}" ]; then
    echo "==> Adding app group ${APP_GROUP} to both entitlements"
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups array" \
        "${BUILD_ROOT}/app.entitlements" >/dev/null
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups:0 string ${APP_GROUP}" \
        "${BUILD_ROOT}/app.entitlements" >/dev/null
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups array" \
        "${BUILD_ROOT}/widget.entitlements" >/dev/null
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups:0 string ${APP_GROUP}" \
        "${BUILD_ROOT}/widget.entitlements" >/dev/null
fi

SIGN_FLAGS="--timestamp=none"
if [ "${IDENTITY}" != "-" ]; then
    SIGN_FLAGS="--options runtime --timestamp"
fi

echo "==> Signing (${IDENTITY})"
codesign --force --sign "${IDENTITY}" ${SIGN_FLAGS} \
    --entitlements "${BUILD_ROOT}/widget.entitlements" "${APPEX}"
codesign --force --sign "${IDENTITY}" ${SIGN_FLAGS} \
    --entitlements "${BUILD_ROOT}/app.entitlements" "${APP}"
codesign --verify --deep --strict "${APP}"

# DMG contents
ln -sfn /Applications "${STAGE}/Applications"
cp "${ROOT}/Scripts/INSTALL.txt" "${STAGE}/Read Me.txt"
if command -v SetFile >/dev/null 2>&1; then
    cp "${APP}/Contents/Resources/AppIcon.icns" "${STAGE}/.VolumeIcon.icns"
    SetFile -a C "${STAGE}" 2>/dev/null || true
    SetFile -a V "${STAGE}/.VolumeIcon.icns" 2>/dev/null || true
fi

echo "==> Creating DMG"
rm -f "${DIST}/${APP_NAME}.dmg"
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGE}" \
    -ov -format UDZO \
    "${DIST}/${APP_NAME}.dmg" >/dev/null
hdiutil verify "${DIST}/${APP_NAME}.dmg" >/dev/null

if [ -n "${NOTARY_PROFILE:-}" ]; then
    echo "==> Notarizing DMG with keychain profile: ${NOTARY_PROFILE}"
    xcrun notarytool submit "${DIST}/${APP_NAME}.dmg" --keychain-profile "${NOTARY_PROFILE}" --wait
    echo "==> Stapling notarization ticket to DMG"
    xcrun stapler staple "${DIST}/${APP_NAME}.dmg"
fi

# Also leave a ready-to-run copy outside the DMG.
rm -rf "${DIST:?}/${APP_NAME}.app"
ditto "${APP}" "${DIST}/${APP_NAME}.app"
codesign --verify --deep --strict "${DIST}/${APP_NAME}.app"

(
    cd "${DIST}"
    shasum -a 256 "${APP_NAME}.dmg" > "SHA256.txt"
)

echo
echo "Built:"
echo "  ${DIST}/${APP_NAME}.app"
echo "  ${DIST}/${APP_NAME}.dmg"
echo
cat "${DIST}/SHA256.txt"
echo
echo "Open the app once, then: desktop → Edit Widgets… → Maxgus World Clock."
