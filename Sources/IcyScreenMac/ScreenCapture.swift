import Foundation

struct ScreenCapture {
    func capture() -> URL? {
        let hostname = ProcessInfo.processInfo.hostName
            .components(separatedBy: ".").first ?? "mac"
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(hostname)_\(timestamp).jpg"
        let outputPath = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent(filename)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        // -x = no shutter sound, -t jpg = JPEG format
        process.arguments = ["-x", "-t", "jpg", outputPath]

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            log("screencapture launch failed: \(error)")
            return nil
        }

        guard process.terminationStatus == 0,
              FileManager.default.fileExists(atPath: outputPath) else {
            log("screencapture produced no output (check Screen Recording permission)")
            return nil
        }

        return URL(fileURLWithPath: outputPath)
    }
}
