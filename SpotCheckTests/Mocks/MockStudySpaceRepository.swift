import Foundation
@testable import SpotCheck

final class MockStudySpaceRepository: StudySpaceRepository {
    var buildingsResult: [CampusBuilding] = []
    var levelsResult: [StudyLevel] = []
    var zonesResult: [StudyZone] = []
    var seatHolds: [SeatHold] = []

    var locationOfNewCheckIns = (seatLabel: "6L3", zoneName: "Library", levelNumber: 6, buildingName: "Building 2")

    var readError: Error?
    var writeError: Error?

    private(set) var addedCheckIns: [SeatCheckIn] = []
    private(set) var updatedCheckIns: [SeatCheckIn] = []

    func buildings() async throws -> [CampusBuilding] {
        try throwReadError()
        return buildingsResult
    }

    func levels(inBuilding buildingID: UUID, at moment: Date) async throws -> [StudyLevel] {
        try throwReadError()
        return levelsResult
    }

    func zones(onLevel levelID: UUID, at moment: Date) async throws -> [StudyZone] {
        try throwReadError()
        return zonesResult
    }

    func activeHold(for occupant: OccupantIdentifier, at moment: Date) async throws -> SeatHold? {
        try throwReadError()
        return seatHolds.first {
            $0.checkIn.checkedInBy == occupant && $0.checkIn.isActive(at: moment)
        }
    }

    func history(for occupant: OccupantIdentifier, at moment: Date) async throws -> [SeatHold] {
        try throwReadError()
        return seatHolds
            .filter { $0.checkIn.checkedInBy == occupant && !$0.checkIn.isActive(at: moment) }
            .sorted { $0.checkIn.checkedInAt > $1.checkIn.checkedInAt }
    }

    func activeCheckIn(onSeat seatID: UUID, at moment: Date) async throws -> SeatCheckIn? {
        try throwReadError()
        return seatHolds.map(\.checkIn).first {
            $0.seatID == seatID && $0.isActive(at: moment)
        }
    }

    func add(_ checkIn: SeatCheckIn) async throws {
        if let writeError { throw writeError }
        addedCheckIns.append(checkIn)
        seatHolds.append(
            SeatHold(
                checkIn: checkIn,
                seatLabel: locationOfNewCheckIns.seatLabel,
                zoneName: locationOfNewCheckIns.zoneName,
                levelNumber: locationOfNewCheckIns.levelNumber,
                buildingName: locationOfNewCheckIns.buildingName
            )
        )
    }

    func update(_ checkIn: SeatCheckIn) async throws {
        if let writeError { throw writeError }
        updatedCheckIns.append(checkIn)
        guard let index = seatHolds.firstIndex(where: { $0.checkIn.id == checkIn.id }) else { return }
        let hold = seatHolds[index]
        seatHolds[index] = SeatHold(
            checkIn: checkIn,
            seatLabel: hold.seatLabel,
            zoneName: hold.zoneName,
            levelNumber: hold.levelNumber,
            buildingName: hold.buildingName
        )
    }

    private func throwReadError() throws {
        if let readError { throw readError }
    }
}
