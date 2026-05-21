import Foundation
import ScreenCaptureKit
import AppKit

struct ScreenCapture {
    let filenameFormat: String

    func capture() -> URL? {
        let semaphore = DispatchSemaphore(value: 0)
        var capturedURL: URL?

        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { content, error in
            if let error = error {
                let code = (error as NSError).code
                log("Screen capture error (\(code)): \(error.localizedDescription)")
                semaphore.signal()
                return
            }

            guard let display = content?.displays.first else {
                log("No display found")
                semaphore.signal()
                return
            }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
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
