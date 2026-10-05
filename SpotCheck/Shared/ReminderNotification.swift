import Foundation

enum ReminderNotification {
    static let categoryIdentifier = "SEAT_EXPIRY_WARNING"

    enum Action {
        static let extendHold = "EXTEND_HOLD"
        static let releaseSeat = "RELEASE_SEAT"
    }

    enum UserInfoKey {
        static let checkInID = "checkInID"
        static let seatLabel = "seatLabel"
        static let zoneName = "zoneName"
        static let levelNumber = "levelNumber"
        static let buildingName = "buildingName"
        static let expiresAt = "expiresAt"
    }
}
