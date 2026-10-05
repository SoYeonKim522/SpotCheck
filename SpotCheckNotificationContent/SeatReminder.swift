import Foundation

struct SeatReminder {
    let seatLabel: String
    let zoneName: String
    let levelNumber: Int
    let buildingName: String
    let expiresAt: Date

    init?(userInfo: [AnyHashable: Any]) {
        typealias Key = ReminderNotification.UserInfoKey
        guard let seatLabel = userInfo[Key.seatLabel] as? String,
              let zoneName = userInfo[Key.zoneName] as? String,
              let levelNumber = userInfo[Key.levelNumber] as? Int,
              let buildingName = userInfo[Key.buildingName] as? String,
              let expiresAt = userInfo[Key.expiresAt] as? TimeInterval
        else { return nil }

        self.seatLabel = seatLabel
        self.zoneName = zoneName
        self.levelNumber = levelNumber
        self.buildingName = buildingName
        self.expiresAt = Date(timeIntervalSince1970: expiresAt)
    }
}
