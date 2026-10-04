import Foundation
@testable import SpotCheck

enum TestData {
    static let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    static func occupant() -> OccupantIdentifier {
        OccupantIdentifier(value: UUID())
    }

    static func checkIn(
        seatID: UUID = UUID(),
        by occupant: OccupantIdentifier = TestData.occupant(),
        at checkedInAt: Date = TestData.now,
        expiresAt: Date? = nil,
        releasedAt: Date? = nil
    ) -> SeatCheckIn {
        SeatCheckIn(
            id: UUID(),
            seatID: seatID,
            checkedInBy: occupant,
            checkedInAt: checkedInAt,
            expiresAt: expiresAt ?? checkedInAt.addingTimeInterval(SeatHoldPolicy.duration),
            releasedAt: releasedAt
        )
    }

    static func seat(
        zoneID: UUID = UUID(),
        label: String = "6L3",
        checkIns: [SeatCheckIn] = []
    ) -> StudySeat {
        StudySeat(
            id: UUID(),
            zoneID: zoneID,
            label: label,
            isByWindow: false,
            hasComputer: false,
            hasPowerOutlet: false,
            hasPartition: false,
            isSharedTable: false,
            checkIns: checkIns
        )
    }

    static func hold(
        of checkIn: SeatCheckIn = TestData.checkIn(),
        seatLabel: String = "6L3",
        zoneName: String = "Library",
        levelNumber: Int = 6,
        buildingName: String = "Building 2"
    ) -> SeatHold {
        SeatHold(
            checkIn: checkIn,
            seatLabel: seatLabel,
            zoneName: zoneName,
            levelNumber: levelNumber,
            buildingName: buildingName
        )
    }

    static func zone(
        levelID: UUID = UUID(),
        name: String = "Library",
        seats: [StudySeat] = []
    ) -> StudyZone {
        StudyZone(id: UUID(), levelID: levelID, name: name, noiseLevel: nil, seats: seats)
    }

    static func level(
        buildingID: UUID = UUID(),
        number: Int = 6,
        zones: [StudyZone] = []
    ) -> StudyLevel {
        StudyLevel(id: UUID(), buildingID: buildingID, number: number, zones: zones)
    }

    static func building(name: String = "Building 2") -> CampusBuilding {
        CampusBuilding(id: UUID(), name: name, address: "61 Broadway, Ultimo", displayOrder: 0)
    }
}
