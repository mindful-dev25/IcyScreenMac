import Foundation
import CoreGraphics

struct PermissionManager {
    static func ensureScreenRecording() {
        guard !CGPreflightScreenCaptureAccess() else { return }

        log("Screen Recording permission not granted — opening System Settings automatically")
        CGRequestScreenCaptureAccess()

        // Poll until the parent grants permission (up to 10 minutes)
        var elapsed = 0
        while !CGPreflightScreenCaptureAccess() {
            Thread.sleep(forTimeInterval: 5)
            elapsed += 5
            if elapsed % 60 == 0 {
                log("Still waiting for Screen Recording permission (\(elapsed)s)…")
                // Re-open System Settings in case the window was dismissed
                CGRequestScreenCaptureAccess()
            }
            if elapsed >= 600 {
                log("Timed out waiting for Screen Recording permission. Will retry on next launch.")
                exit(1)
            }
        }

        log("Screen Recording permission granted")
    }
}
