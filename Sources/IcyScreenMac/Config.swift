import Foundation

struct Config {
    private static let env = ProcessInfo.processInfo.environment

    let intervalMinutes: Int    = Int(env["ICS_INTERVAL"] ?? "") ?? 2
    let ftpHost: String         = env["ICS_FTP_HOST"]     ?? "192.168.3.21"
    let ftpUsername: String     = env["ICS_FTP_USERNAME"] ?? "lyg0711"
    let ftpPassword: String     = env["ICS_FTP_PASSWORD"] ?? ""
    let ftpRemotePath: String   = env["ICS_FTP_PATH"]     ?? "/1/KJR/mac"
    let filenameFormat: String  = "yy-MM-dd_HH_mm_ss"
}
