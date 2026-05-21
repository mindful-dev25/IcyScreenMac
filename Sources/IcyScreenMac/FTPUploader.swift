import Foundation

struct FTPUploader {
    let config: Config

    func upload(fileURL: URL) {
        let filename = fileURL.lastPathComponent
        var remotePath = config.ftpRemotePath
        if !remotePath.hasSuffix("/") { remotePath += "/" }
        let ftpURL = "ftp://\(config.ftpHost)\(remotePath)\(filename)"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        process.arguments = [
            "--silent",
            "--show-error",
            "--ftp-create-dirs",
            "--user", "\(config.ftpUsername):\(config.ftpPassword)",
            "--connect-timeout", "30",
            "-T", fileURL.path,
            ftpURL
        ]

        let errPipe = Pipe()
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            log("curl launch failed: \(error)")
            cleanup(fileURL)
            return
        }

        if process.terminationStatus == 0 {
            log("Uploaded \(filename)")
        } else {
            let msg = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(),
                            encoding: .utf8) ?? ""
            log("Upload failed (\(process.terminationStatus)): \(msg.trimmingCharacters(in: .whitespacesAndNewlines))")
        }

        cleanup(fileURL)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
