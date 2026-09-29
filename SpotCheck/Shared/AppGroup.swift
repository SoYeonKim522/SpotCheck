import Foundation

enum AppGroup {
    static let identifier = "group.com.soyeonkim.spotcheck"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
