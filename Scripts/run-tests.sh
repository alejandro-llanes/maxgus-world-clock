#!/bin/bash
#
# Run the WorldClockTests unit tests from the command line (same as ⌘U in Xcode).
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

xcodebuild \
    -project "${ROOT}/MaxgusWorldClock.xcodeproj" \
    -scheme MaxgusWorldClock \
    -destination "platform=macOS,arch=$(uname -m)" \
    -derivedDataPath "${ROOT}/build/tests" \
    CODE_SIGN_IDENTITY=- \
    -quiet \
    test
