#!/bin/bash
#
# Regenerate Scripts/AppIntentsMetadata from the widget's App Intents sources.
#
# Xcode normally runs appintentsmetadataprocessor as part of the widget target
# build. The DMG script only needs the checked-in metadata, so this helper is
# for development: run it after changing WorldClockConfigurationIntent,
# CityEntity, or CityQuery, then commit/copy the regenerated files.
#
# Requirements: Xcode (for appintentsmetadataprocessor) and Command Line Tools.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIN_MACOS="${MIN_MACOS:-14.0}"
TARGET="${TARGET:-arm64-apple-macosx${MIN_MACOS}}"
PROTOCOLS_JSON='["AppIntent","AppEntity","AppEnum","EntityQuery","EntityStringQuery","WidgetConfigurationIntent","AppValue"]'

# The metadata processor lives in Xcode, not the Command Line Tools. Find it
# even when xcode-select currently points at the CLT.
XCODE_DEV="${XCODE_DEV:-$(xcode-select -p 2>/dev/null || true)}"
PROCESSOR="${XCODE_DEV}/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor"
if [ ! -x "${PROCESSOR}" ] && [ -x "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor" ]; then
    XCODE_DEV="/Applications/Xcode.app/Contents/Developer"
    PROCESSOR="${XCODE_DEV}/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor"
fi
if [ ! -x "${PROCESSOR}" ]; then
    echo "error: appintentsmetadataprocessor not found." >&2
    echo "Install Xcode or set XCODE_DEV to an Xcode Developer directory." >&2
    exit 1
fi

# Compile with the Command Line Tools when nothing else is specified. The
# processor itself is a standalone Xcode tool and runs without opening Xcode or
# accepting its IDE license. An externally supplied DEVELOPER_DIR always wins,
# so a stale Command Line Tools install can be worked around by pointing at
# the full Xcode (see check_toolchain below).
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d "/Library/Developer/CommandLineTools" ]; then
    export DEVELOPER_DIR="/Library/Developer/CommandLineTools"
fi

# The Command Line Tools and the full Xcode ship their own SDKs, and a
# half-updated install pairs a newer compiler with an older SDK. Swift then
# refuses to build anything ("this SDK is not supported by the compiler").
# Fail early with an actionable message instead of a wall of compiler output.
check_toolchain() {
    local probe="${WORK:-$(mktemp -d)}/probe.swift"
    mkdir -p "$(dirname "${probe}")"
    printf 'let x = 1\n' > "${probe}"
    if ! "${SWIFTC}" -typecheck -sdk "${SDK}" -module-cache-path "$(dirname "${probe}")/modcache" "${probe}" >/dev/null 2>&1; then
        echo "error: the Swift toolchain at ${DEVELOPER_DIR} cannot build against its own SDK." >&2
        echo "       This usually means the Command Line Tools are only half updated." >&2
        echo "       Fix it by pointing DEVELOPER_DIR at the full Xcode:" >&2
        echo "         DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer $0" >&2
        echo "       or by updating the Command Line Tools in Software Update." >&2
        exit 1
    fi
}
SDK="$(xcrun --show-sdk-path)"
SWIFTC="$(xcrun --find swiftc)"
XCODE_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :ProductBuildVersion' "$(dirname "${XCODE_DEV}")/version.plist" 2>/dev/null || true)"
if [ -z "${XCODE_VERSION}" ]; then
    XCODE_VERSION="unknown"
fi

WORK="${ROOT}/build/appintents"
rm -rf "${WORK}"
mkdir -p "${WORK}/cv" "${WORK}/Resources" "${WORK}/modcache"
printf '%s' "${PROTOCOLS_JSON}" > "${WORK}/protocols.json"

check_toolchain

echo "==> Generating App Intents metadata with ${XCODE_VERSION}"

# Swift emits const values per primary source file. The metadata processor
# uses these plus the source list to extract intent and entity information.
compile_const_values() {
    local primary="$1"
    local output="$2"
    shift 2
    rm -f "${output}"
    echo "    const values: $(basename "${primary}")"
    "${SWIFTC}" -frontend -typecheck -primary-file "${primary}" \
        -module-name WorldClockWidget \
        -sdk "${SDK}" -target "${TARGET}" -swift-version 5 \
        -application-extension -parse-as-library \
        -module-cache-path "${WORK}/modcache" \
        -const-gather-protocols-file "${WORK}/protocols.json" \
        -emit-const-values-path "${output}" \
        "$@"
}

compile_const_values \
    "${ROOT}/WorldClockWidget/WorldClockWidget.swift" \
    "${WORK}/cv/intent.swiftconstvalues" \
    "${ROOT}/Shared/"*.swift

compile_const_values \
    "${ROOT}/Shared/CityEntity.swift" \
    "${WORK}/cv/entity.swiftconstvalues" \
    "${ROOT}/Shared/CityCatalog.swift" \
    "${ROOT}/Shared/CityTime.swift" \
    "${ROOT}/Shared/WidgetViews.swift"

cat > "${WORK}/sources.txt" <<EOF
${ROOT}/WorldClockWidget/WorldClockWidget.swift
${ROOT}/Shared/CityEntity.swift
${ROOT}/Shared/CityCatalog.swift
${ROOT}/Shared/CityTime.swift
${ROOT}/Shared/WidgetViews.swift
EOF
cat > "${WORK}/constvals.txt" <<EOF
${WORK}/cv/intent.swiftconstvalues
${WORK}/cv/entity.swiftconstvalues
EOF

"${PROCESSOR}" \
    --output "${WORK}/Resources" \
    --toolchain-dir "${DEVELOPER_DIR}/usr" \
    --module-name WorldClockWidget \
    --sdk-root "${SDK}" \
    --xcode-version "${XCODE_VERSION}" \
    --platform-family macOS \
    --deployment-target "${MIN_MACOS}" \
    --target-triple "${TARGET}" \
    --source-file-list "${WORK}/sources.txt" \
    --swift-const-vals-list "${WORK}/constvals.txt" \
    --compile-time-extraction \
    --deployment-aware-processing \
    --no-app-shortcuts-localization \
    --force

METADATA="${WORK}/Resources/Metadata.appintents"
if [ ! -f "${METADATA}/extract.actionsdata" ]; then
    echo "error: metadata processor did not produce extract.actionsdata" >&2
    exit 1
fi

rm -rf "${ROOT}/Scripts/AppIntentsMetadata"
mkdir -p "${ROOT}/Scripts/AppIntentsMetadata"
cp "${METADATA}/extract.actionsdata" "${ROOT}/Scripts/AppIntentsMetadata/extract.actionsdata"
cp "${METADATA}/version.json" "${ROOT}/Scripts/AppIntentsMetadata/version.json"
python3 -m json.tool "${ROOT}/Scripts/AppIntentsMetadata/extract.actionsdata" >/dev/null
python3 -m json.tool "${ROOT}/Scripts/AppIntentsMetadata/version.json" >/dev/null

echo
echo "Wrote:"
echo "  ${ROOT}/Scripts/AppIntentsMetadata/extract.actionsdata"
echo "  ${ROOT}/Scripts/AppIntentsMetadata/version.json"
echo
echo "Rebuild the DMG with ./Scripts/build-dmg.sh"
