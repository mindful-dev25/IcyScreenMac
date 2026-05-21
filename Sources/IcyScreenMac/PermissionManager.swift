import Foundation
import AppKit

struct PermissionManager {
    static func openScreenRecordingSettings() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        )
    }
}
