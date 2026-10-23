#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${ROOT}/build/tests"
rm -rf "${WORK}"
mkdir -p "${WORK}"

SDK="$(xcrun --show-sdk-path)"
PLATFORM_DIR="$(xcrun --show-sdk-platform-path)"

cat > "${WORK}/main.swift" <<'EOF'
import Foundation
import XCTest

class TestObserver: NSObject, XCTestObservation {
    var failCount = 0

    func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: Int) {
        failCount += 1
        print("FAIL: \(testCase.name) at line \(lineNumber): \(description)")
    }

    func testCaseDidFinish(_ testCase: XCTestCase) {
        if testCase.testRun?.hasSucceeded == true {
            print("PASS: \(testCase.name)")
        }
    }
}

let observer = TestObserver()
XCTestObservationCenter.shared.addTestObserver(observer)

let suite = XCTestSuite(forTestCaseClass: WorldClockTests.self)
print("==> Running \(suite.testCaseCount) World Clock tests...")
suite.run()

if observer.failCount > 0 {
    print("\nTests failed: \(observer.failCount)")
    exit(1)
} else {
    print("\nAll \(suite.testCaseCount) tests passed!")
    exit(0)
}
EOF

xcrun swiftc -O -sdk "${SDK}" \
    -module-cache-path "${WORK}/modcache" \
    -swift-version 5 \
    -I "${PLATFORM_DIR}/Developer/usr/lib" \
    -F "${PLATFORM_DIR}/Developer/Library/Frameworks" \
    -L "${PLATFORM_DIR}/Developer/usr/lib" \
    -framework XCTest -framework Foundation -framework SwiftUI -framework AppIntents -framework WidgetKit \
    -Xlinker -rpath -Xlinker "${PLATFORM_DIR}/Developer/Library/Frameworks" \
    -Xlinker -rpath -Xlinker "${PLATFORM_DIR}/Developer/usr/lib" \
    "${ROOT}/Shared/"*.swift "${ROOT}/Tests/"*.swift "${WORK}/main.swift" \
    -o "${WORK}/test-runner"

"${WORK}/test-runner"
