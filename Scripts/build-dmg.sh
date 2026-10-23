#!/bin/bash
#
# Build Maxgus World Clock with Xcode and package it as a DMG.
#
#   ./Scripts/build-dmg.sh
#
# Produces a universal (Apple silicon + Intel) Release build, signed to run
# locally (ad-hoc). To sign with a Developer ID and notarize instead:
#
#   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE="AC_PASSWORD" \
#     ./Scripts/build-dmg.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Maxgus World Clock"
IDENTITY="${CODESIGN_IDENTITY:--}"

BUILD_ROOT="${ROOT}/build/installer"
DERIVED="${BUILD_ROOT}/DerivedData"
STAGE="${BUILD_ROOT}/dmg"
APP="${STAGE}/${APP_NAME}.app"
DIST="${ROOT}/dist"

# Without this, Xcode adds the get-task-allow (debugger) entitlement to
# ad-hoc builds, which notarization rejects.
SIGNING=(CODE_SIGN_IDENTITY="${IDENTITY}" CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO)
if [ "${IDENTITY}" != "-" ]; then
    TEAM="$(sed -n 's/.*(\([A-Z0-9]*\))$/\1/p' <<< "${IDENTITY}")"
    if [ -z "${TEAM}" ]; then
        echo "error: CODESIGN_IDENTITY must end with the team ID, e.g. \"... (ABCDE12345)\"" >&2
        exit 1
    fi
    SIGNING+=(CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="${TEAM}" OTHER_CODE_SIGN_FLAGS=--timestamp)
fi

echo "==> Building ${APP_NAME} (Release, arm64 + x86_64, signing: ${IDENTITY})"
rm -rf "${BUILD_ROOT}"
mkdir -p "${STAGE}" "${DIST}"

# Xcode also generates the App Intents metadata the widget's Edit Widget panel
# depends on, so nothing here needs to be kept in sync by hand.
xcodebuild \
    -project "${ROOT}/MaxgusWorldClock.xcodeproj" \
    -scheme MaxgusWorldClock \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "${DERIVED}" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    "${SIGNING[@]}" \
    -quiet \
    build

# Xcode names the bundle after the target; ship it under the display name.
PRODUCT="${DERIVED}/Build/Products/Release/MaxgusWorldClock.app"
ditto "${PRODUCT}" "${APP}"
codesign --verify --deep --strict "${APP}"

# Xcode registers every app it builds with LaunchServices. Unregister the build
# copy so macOS never runs the widget from here instead of /Applications.
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
pluginkit -r "${PRODUCT}/Contents/PlugIns/WorldClockWidget.appex" 2>/dev/null || true
"${LSREGISTER}" -u "${PRODUCT}" 2>/dev/null || true

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
