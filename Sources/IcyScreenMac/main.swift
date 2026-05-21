import Foundation

if CommandLine.arguments.contains("--configure") {
    Configurator.run()
    exit(0)
}

log("Starting (pid \(ProcessInfo.processInfo.processIdentifier))")

PermissionManager.ensureScreenRecording()

let config = Config.load()

guard !config.ftpHost.isEmpty else {
    log("FTP host not configured — edit ~/.icyscreen/config.json and restart")
    exit(1)
}

log("Interval: \(config.intervalMinutes) min | FTP: \(config.ftpHost)\(config.ftpRemotePath)")

let capture  = ScreenCapture(filenameFormat: config.filenameFormat)
let uploader = FTPUploader(config: config)

// Serial queue — captures never overlap even if one runs long
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
