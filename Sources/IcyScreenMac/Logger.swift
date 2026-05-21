import Foundation

private let logDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return f
}()

func log(_ message: String) {
    let timestamp = logDateFormatter.string(from: Date())
    let output = FileHandle.standardError
    let line = "[\(timestamp)] IcyScreen: \(message)\n"
    output.write(Data(line.utf8))
}
