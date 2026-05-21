import Foundation
import CoreGraphics

struct PermissionManager {
    static var hasPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    // Call once at startup — opens System Settings if not yet granted, then returns immediately.
    static func requestIfNeeded() {
        guard !hasPermission else { return }
        log("Screen Recording permission not granted — opening System Settings")
        CGRequestScreenCaptureAccess()
    }
}
