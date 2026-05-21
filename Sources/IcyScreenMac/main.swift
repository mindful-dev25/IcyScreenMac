import Foundation

log("Starting (pid \(ProcessInfo.processInfo.processIdentifier))")

let config   = Config()
let capture  = ScreenCapture(filenameFormat: config.filenameFormat)
let uploader = FTPUploader(config: config)

log("Interval: \(config.intervalMinutes) min | FTP: \(config.ftpHost)\(config.ftpRemotePath)")

let captureQueue = DispatchQueue(label: "com.icyscreen.capture", qos: .background)

func captureAndUpload() {
    captureQueue.async {
        log("Capturing screenshot")
        guard let fileURL = capture.capture() else { return }
        uploader.upload(fileURL: fileURL)
    }
}

captureAndUpload()

let intervalSeconds = TimeInterval(max(1, config.intervalMinutes) * 60)
Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { _ in
    captureAndUpload()
}

RunLoop.main.run()
