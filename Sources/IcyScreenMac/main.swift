import Foundation

log("Starting (pid \(ProcessInfo.processInfo.processIdentifier))")

PermissionManager.ensureScreenRecording()

let config = Config.load()

guard !config.ftpHost.isEmpty else {
    log("FTP host not configured — edit ~/.icyscreen/config.json and restart")
    exit(1)
}

log("Interval: \(config.intervalMinutes) min | FTP: \(config.ftpHost)\(config.ftpRemotePath)")

let capture = ScreenCapture()
let uploader = FTPUploader(config: config)

func captureAndUpload() {
    log("Capturing screenshot")
    guard let fileURL = capture.capture() else { return }
    uploader.upload(fileURL: fileURL)
}

// First capture immediately on start
captureAndUpload()

let intervalSeconds = TimeInterval(max(1, config.intervalMinutes) * 60)
Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { _ in
    captureAndUpload()
}

RunLoop.main.run()
