import Foundation

struct Config: Codable {
    var intervalMinutes: Int
    var ftpHost: String
    var ftpUsername: String
    var ftpPassword: String
    var ftpRemotePath: String

    init() {
        intervalMinutes = 2
        ftpHost = ""
        ftpUsername = ""
        ftpPassword = ""
        ftpRemotePath = "/screenshots"
    }

    static var configURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".icyscreen/config.json")
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
