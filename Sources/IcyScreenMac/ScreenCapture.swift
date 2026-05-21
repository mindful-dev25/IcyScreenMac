import Foundation
import ScreenCaptureKit
import AppKit

struct ScreenCapture {
    let filenameFormat: String

    func capture() -> URL? {
        guard PermissionManager.hasPermission else {
            log("Skipping capture — Screen Recording permission not granted. Grant it in System Settings → Privacy & Security → Screen Recording → IcyScreen")
            PermissionManager.requestIfNeeded()
            return nil
        }

        let semaphore = DispatchSemaphore(value: 0)
        var capturedURL: URL?

        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { content, error in
            guard let display = content?.displays.first else {
                log("No display found: \(error?.localizedDescription ?? "unknown")")
                semaphore.signal()
                return
            }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            // Use display's native point dimensions — SCK scales to pixels internally
            config.width  = display.width
            config.height = display.height

            SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { cgImage, error in
                defer { semaphore.signal() }
                guard let cgImage else {
                    log("Capture failed: \(error?.localizedDescription ?? "unknown")")
                    return
                }
                capturedURL = saveAsJPEG(cgImage)
            }
        }

        // 30-second hard timeout so we never hang the capture queue
        if semaphore.wait(timeout: .now() + 30) == .timedOut {
            log("Screenshot capture timed out")
        }
        return capturedURL
    }

    private func saveAsJPEG(_ cgImage: CGImage) -> URL? {
        let nsImage = NSImage(cgImage: cgImage, size: .zero)
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            log("Failed to encode as JPEG")
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = filenameFormat
        let filename = "\(formatter.string(from: Date())).jpg"
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(filename)

        do {
            try jpegData.write(to: outputURL)
            return outputURL
        } catch {
            log("Failed to write screenshot: \(error)")
            return nil
        }
    }
}
