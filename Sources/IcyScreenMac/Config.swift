import Foundation

struct Config: Codable {
    var intervalMinutes: Int
    var ftpHost: String
    var ftpUsername: String
    var ftpPassword: String
    var ftpRemotePath: String
    var filenameFormat: String

    init() {
        intervalMinutes = 2
        ftpHost = "192.168.3.21"
        ftpUsername = "lyg0711"
        ftpPassword = ""
        ftpRemotePath = "/1/KJR/mac"
        filenameFormat = "yy-MM-dd_HH_mm_ss"
    }

    static var configURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".icyscreen/config.json")
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        intervalMinutes = try c.decodeIfPresent(Int.self,    forKey: .intervalMinutes) ?? 2
        ftpHost         = try c.decodeIfPresent(String.self, forKey: .ftpHost)         ?? "192.168.3.21"
        ftpUsername     = try c.decodeIfPresent(String.self, forKey: .ftpUsername)     ?? "lyg0711"
        ftpPassword     = try c.decodeIfPresent(String.self, forKey: .ftpPassword)     ?? ""
        ftpRemotePath   = try c.decodeIfPresent(String.self, forKey: .ftpRemotePath)   ?? ""
        filenameFormat  = try c.decodeIfPresent(String.self, forKey: .filenameFormat)  ?? "yy-MM-dd_HH_mm_ss"
    }

    static func load() -> Config {
        let url = configURL
        guard let data = try? Data(contentsOf: url) else {
            log("Config not found at \(url.path)")
            return Config()
        }
        do {
            return try JSONDecoder().decode(Config.self, from: data)
        } catch {
            log("Failed to parse config: \(error)")
            return Config()
        }
    }
}
