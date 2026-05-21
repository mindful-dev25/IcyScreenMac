import Foundation

struct FTPUploader {
    let config: Config

    func upload(fileURL: URL) {
        let filename = fileURL.lastPathComponent
        var remotePath = config.ftpRemotePath
        if !remotePath.hasSuffix("/") { remotePath += "/" }
        let ftpURL = "ftp://\(config.ftpHost)\(remotePath)\(filename)"

        log("Uploading to \(ftpURL)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        process.arguments = [
            "--verbose",
            "--ftp-pasv",           // passive mode — required behind NAT/router
            "--ftp-create-dirs",
            "--user", "\(config.ftpUsername):\(config.ftpPassword)",
            "--connect-timeout", "30",
            "-T", fileURL.path,
            ftpURL
        ]
        // stderr inherits from parent → goes to /tmp/icyscreen.log via LaunchAgent plist.
        // Do NOT redirect to a Pipe — curl's verbose output can deadlock waitUntilExit().

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            log("curl launch failed: \(error)")
            cleanup(fileURL)
            return
        }

        if process.terminationStatus == 0 {
            log("Upload succeeded: \(filename)")
        } else {
            log("Upload failed (curl exit \(process.terminationStatus)) — see verbose output above")
        }

        cleanup(fileURL)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
