import Foundation

/// Remembers the building the student last chose, so the level list opens on it.
/// It also remembers whether someone is signed in, so the widget can ask them to sign in.
///
/// It uses the App Group's `UserDefaults`, so the widget can read the same values.
/// It holds no seat or check-in data. That data stays in the database.
struct AppSettingsStore {
    private let defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard

    var lastBuildingID: UUID? {
        get { defaults.string(forKey: Key.lastBuildingID).flatMap(UUID.init(uuidString:)) }
        nonmutating set { defaults.set(newValue?.uuidString, forKey: Key.lastBuildingID) }
    }

    var isSignedIn: Bool {
        get { defaults.bool(forKey: Key.isSignedIn) }
        nonmutating set { defaults.set(newValue, forKey: Key.isSignedIn) }
    }

    private enum Key {
        static let lastBuildingID = "lastBuildingID"
        static let isSignedIn = "isSignedIn"
    }
}
