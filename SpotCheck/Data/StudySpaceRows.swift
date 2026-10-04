import Foundation

/// The shapes the tables come back in, and how they become domain structs.
///
/// Row types stay in the data layer. Nothing above it knows that a zone arrives nested inside
/// a level, or that a seat's check-ins arrive already filtered down to the active ones.
/// Zones and seat labels are sorted here with `localizedStandardCompare`, so "Seat 10" comes
/// after "Seat 9" rather than before it.
struct BuildingRow: Decodable {
    let id: UUID
    let name: String
    let address: String
    let displayOrder: Int

    var building: CampusBuilding {
        CampusBuilding(id: id, name: name, address: address, displayOrder: displayOrder)
    }
}

struct LevelRow: Decodable {
    let id: UUID
    let buildingId: UUID
    let number: Int
    let zones: [ZoneRow]?

    var level: StudyLevel {
        StudyLevel(
            id: id,
            buildingID: buildingId,
            number: number,
            zones: (zones ?? [])
                .map(\.zone)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        )
    }
}

struct ZoneRow: Decodable {
    let id: UUID
    let levelId: UUID
    let name: String
    let noiseLevel: NoiseLevel?
    let seats: [SeatRow]

    var zone: StudyZone {
        StudyZone(
            id: id,
            levelID: levelId,
            name: name,
            noiseLevel: noiseLevel,
            seats: seats.map(\.seat).sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }
        )
    }
}

struct SeatRow: Decodable {
    let id: UUID
    let zoneId: UUID
    let label: String
    let isByWindow: Bool
    let hasComputer: Bool
    let hasPowerOutlet: Bool
    let hasPartition: Bool
    let isSharedTable: Bool
    let seatCheckIns: [CheckInRow]

    var seat: StudySeat {
        StudySeat(
            id: id,
            zoneID: zoneId,
            label: label,
            isByWindow: isByWindow,
            hasComputer: hasComputer,
            hasPowerOutlet: hasPowerOutlet,
            hasPartition: hasPartition,
            isSharedTable: isSharedTable,
            checkIns: seatCheckIns.map(\.checkIn)
        )
    }
}

struct CheckInRow: Decodable {
    let id: UUID
    let seatId: UUID
    let occupantId: UUID
    let checkedInAt: Date
    let expiresAt: Date
    let releasedAt: Date?

    var checkIn: SeatCheckIn {
        SeatCheckIn(
            id: id,
            seatID: seatId,
            checkedInBy: OccupantIdentifier(value: occupantId),
            checkedInAt: checkedInAt,
            expiresAt: expiresAt,
            releasedAt: releasedAt
        )
    }
}

/// A check-in read together with the seat it is on, through to the building.
struct HoldRow: Decodable {
    let id: UUID
    let seatId: UUID
    let occupantId: UUID
    let checkedInAt: Date
    let expiresAt: Date
    let releasedAt: Date?
    let seats: SeatPlaceRow

    var hold: SeatHold {
        SeatHold(
            checkIn: CheckInRow(
                id: id,
                seatId: seatId,
                occupantId: occupantId,
                checkedInAt: checkedInAt,
                expiresAt: expiresAt,
                releasedAt: releasedAt
            ).checkIn,
            seatLabel: seats.label,
            zoneName: seats.zones.name,
            levelNumber: seats.zones.levels.number,
            buildingName: seats.zones.levels.buildings.name
        )
    }
}

struct SeatPlaceRow: Decodable {
    let label: String
    let zones: ZonePlaceRow
}

struct ZonePlaceRow: Decodable {
    let name: String
    let levels: LevelPlaceRow
}

struct LevelPlaceRow: Decodable {
    let number: Int
    let buildings: BuildingPlaceRow
}

struct BuildingPlaceRow: Decodable {
    let name: String
}

/// The columns sent when a check-in is made. The others are left to their defaults.
struct NewCheckInRow: Encodable {
    let id: UUID
    let seatId: UUID
    let occupantId: UUID
    let checkedInAt: Date
    let expiresAt: Date

    init(_ checkIn: SeatCheckIn) {
        id = checkIn.id
        seatId = checkIn.seatID
        occupantId = checkIn.checkedInBy.value
        checkedInAt = checkIn.checkedInAt
        expiresAt = checkIn.expiresAt
    }
}

/// The only two columns a check-in can change after it is made: it can be pushed out, or ended.
struct CheckInChangeRow: Encodable {
    let expiresAt: Date
    let releasedAt: Date?

    init(_ checkIn: SeatCheckIn) {
        expiresAt = checkIn.expiresAt
        releasedAt = checkIn.releasedAt
    }
}
