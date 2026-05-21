import Foundation
import CoreGraphics
import AppKit

struct ScreenCapture {
    func capture() -> URL? {
        guard let cgImage = CGDisplayCreateImage(CGMainDisplayID()) else {
            log("CGDisplayCreateImage failed — Screen Recording permission may have been revoked")
            return nil
        }

        let nsImage = NSImage(cgImage: cgImage, size: .zero)
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            log("Failed to encode screenshot as JPEG")
            return nil
        }

        let hostname = ProcessInfo.processInfo.hostName
            .components(separatedBy: ".").first ?? "mac"
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(hostname)_\(timestamp).jpg"
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)

        do {
            try jpegData.write(to: outputURL)
            return outputURL
        } catch {
            log("Failed to write screenshot: \(error)")
            return nil
        }
    }
}
