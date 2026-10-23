import AppKit
import SwiftUI

@main
struct MaxgusWorldClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 900, height: 870)
        .defaultPosition(.center)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // AppKit can restore a window frame from a previous display setup that
        // is no longer attached. If the window isn't substantially visible on
        // any current screen, put it back in the center of the main display.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            for window in NSApp.windows where window.canBecomeMain {
                if !Self.isVisibleOnAnyScreen(window) {
                    window.center()
                }
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private static func isVisibleOnAnyScreen(_ window: NSWindow) -> Bool {
        NSScreen.screens.contains { screen in
            let visiblePart = window.frame.intersection(screen.visibleFrame)
            return visiblePart.width >= 120 && visiblePart.height >= 120
        }
    }
}
