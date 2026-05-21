import Foundation
import Darwin

struct Configurator {
    static func run() {
        var config = Config.load()

        print("""

=== IcyScreen Configuration ===
Press Enter to keep the current value.

""")

        config.ftpHost       = ask("FTP host",            current: config.ftpHost)
        config.ftpUsername   = ask("FTP username",        current: config.ftpUsername)
        config.ftpPassword   = askSecret("FTP password",  current: config.ftpPassword)
        config.ftpRemotePath = ask("Remote path", current: config.ftpRemotePath)
        config.intervalMinutes = askInt("Capture interval (minutes)",
                                        current: config.intervalMinutes)
        config.filenameFormat  = ask("Filename format (DateFormatter pattern)",
                                     current: config.filenameFormat)

        save(config)

        let agentInstalled = FileManager.default.fileExists(
            atPath: FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/LaunchAgents/com.icyscreen.agent.plist").path
        )
        if agentInstalled { restartAgent() }

        print("""

Settings saved.
  Host:     \(config.ftpHost)
  User:     \(config.ftpUsername)
  Path:     \(config.ftpRemotePath)
  Interval: \(config.intervalMinutes) min
  Filename: \(config.filenameFormat).jpg
\(agentInstalled ? "\nAgent restarted with new settings." : "")
""")
    }

    // MARK: - Prompts

    private static func ask(_ label: String, current: String) -> String {
        let hint = current.isEmpty ? "" : " [\(current)]"
        print("\(label)\(hint): ", terminator: "")
        fflush(stdout)
        let input = readLine(strippingNewline: true) ?? ""
        return input.isEmpty ? current : input
    }

    private static func askInt(_ label: String, current: Int) -> Int {
        print("\(label) [\(current)]: ", terminator: "")
        fflush(stdout)
        let input = readLine(strippingNewline: true) ?? ""
        guard !input.isEmpty, let value = Int(input), value > 0 else { return current }
        return value
    }

    private static func askSecret(_ label: String, current: String) -> String {
        let hint = current.isEmpty ? "not set" : "set — Enter to keep"
        print("\(label) [\(hint)]: ", terminator: "")
        fflush(stdout)

        // Disable terminal echo for password input
        var saved = termios()
        tcgetattr(STDIN_FILENO, &saved)
        var silent = saved
        silent.c_lflag &= ~tcflag_t(ECHO)
        tcsetattr(STDIN_FILENO, TCSANOW, &silent)

        let input = readLine(strippingNewline: true) ?? ""

        tcsetattr(STDIN_FILENO, TCSANOW, &saved)
        print("") // move past the hidden input line

        return input.isEmpty ? current : input
    }

    // MARK: - Persist & restart

    private static func save(_ config: Config) {
        let url = Config.configURL
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: url)
            // Keep config readable only by the owner
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        } catch {
            print("ERROR: Could not save config: \(error)")
            exit(1)
        }
    }

    private static func restartAgent() {
        let plist = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.icyscreen.agent.plist").path

        for args in [["unload", plist], ["load", "-w", plist]] {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            p.arguments = args
            try? p.run()
            p.waitUntilExit()
        }
    }
}
