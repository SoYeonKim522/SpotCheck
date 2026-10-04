import Foundation
import Testing
@testable import SpotCheck

@MainActor
struct ViewLevelAvailabilityUseCaseTests {
    let repository = MockStudySpaceRepository()
    let widget = MockWidgetRefresher()
    let snapshot = MockSnapshotWriter()

    var useCase: ViewLevelAvailabilityUseCase {
        ViewLevelAvailabilityUseCase(
            repository: repository,
            widget: widget,
            snapshot: snapshot
        )
    }

    @Test func aLevelCountsItsFreeSeatsAndItsTotal() async throws {
        let building = TestData.building()
        let readingRoom = TestData.zone(
            name: "Reading Room",
            seats: [TestData.seat(checkIns: [TestData.checkIn()]), TestData.seat(), TestData.seat()]
        )
        let library = TestData.zone(
            name: "Library",
            seats: [TestData.seat(checkIns: [TestData.checkIn()]), TestData.seat()]
        )
        repository.levelsResult = [TestData.level(buildingID: building.id, zones: [readingRoom, library])]

        let availabilities = try await useCase.execute(building: building, now: TestData.now)

        #expect(availabilities.map(\.free) == [3])
        #expect(availabilities.map(\.total) == [5])
    }

    @Test func anExpiredCheckInDoesNotCountTowardsOccupancy() async throws {
        let building = TestData.building()
        let expired = TestData.checkIn(at: TestData.now.addingTimeInterval(-2 * 60 * 60))
        let seat = TestData.seat(checkIns: [expired])
        repository.levelsResult = [TestData.level(buildingID: building.id, zones: [TestData.zone(seats: [seat])])]

        let availabilities = try await useCase.execute(building: building, now: TestData.now)

        #expect(availabilities.map(\.free) == [1])
        #expect(availabilities.map(\.total) == [1])
    }

    @Test func aReleasedCheckInDoesNotCountTowardsOccupancy() async throws {
        let building = TestData.building()
        let released = TestData.checkIn(
            at: TestData.now.addingTimeInterval(-30 * 60),
            releasedAt: TestData.now.addingTimeInterval(-10 * 60)
        )
        let seat = TestData.seat(checkIns: [released])
        repository.levelsResult = [TestData.level(buildingID: building.id, zones: [TestData.zone(seats: [seat])])]

        let availabilities = try await useCase.execute(building: building, now: TestData.now)

        #expect(availabilities.map(\.free) == [1])
    }

    @Test func aSeatIsFreeAtTheMomentItsCheckInExpires() async throws {
        let building = TestData.building()
        let expiringNow = TestData.checkIn(at: TestData.now.addingTimeInterval(-60 * 60))
        let seat = TestData.seat(checkIns: [expiringNow])
        repository.levelsResult = [TestData.level(buildingID: building.id, zones: [TestData.zone(seats: [seat])])]

        let availabilities = try await useCase.execute(building: building, now: TestData.now)

        #expect(availabilities.map(\.free) == [1])
    }

    @Test func aLevelWithEverySeatHeldReportsZeroFree() async throws {
        let building = TestData.building()
        let seats = (0..<3).map { _ in TestData.seat(checkIns: [TestData.checkIn()]) }
        repository.levelsResult = [TestData.level(buildingID: building.id, zones: [TestData.zone(seats: seats)])]

        let availabilities = try await useCase.execute(building: building, now: TestData.now)

        #expect(availabilities.map(\.free) == [0])
        #expect(availabilities.map(\.total) == [3])
    }

    @Test func availabilityCarriesTheMomentItWasRead() async throws {
        let building = TestData.building()
        repository.levelsResult = [
            TestData.level(buildingID: building.id, number: 5),
            TestData.level(buildingID: building.id, number: 6)
        ]
        let readAt = TestData.now.addingTimeInterval(5 * 60)

        let availabilities = try await useCase.execute(building: building, now: readAt)

        #expect(availabilities.map(\.lastUpdatedAt) == [readAt, readAt])
    }

    @Test func everyLevelOfTheBuildingGetsItsOwnCount() async throws {
        let building = TestData.building()
        let levelFive = TestData.level(
            buildingID: building.id,
            number: 5,
            zones: [TestData.zone(seats: [TestData.seat(checkIns: [TestData.checkIn()]), TestData.seat()])]
        )
        let levelSix = TestData.level(
            buildingID: building.id,
            number: 6,
            zones: [TestData.zone(seats: [TestData.seat(), TestData.seat(), TestData.seat()])]
        )
        repository.levelsResult = [levelFive, levelSix]

        let availabilities = try await useCase.execute(building: building, now: TestData.now)

        #expect(availabilities.map(\.level.number) == [5, 6])
        #expect(availabilities.map(\.free) == [1, 3])
        #expect(availabilities.map(\.total) == [2, 3])
    }

    @Test func readingAvailabilityWritesTheSnapshotAndReloadsTheWidget() async throws {
        let building = TestData.building(name: "Building 1")
        let level = TestData.level(
            buildingID: building.id,
            number: 5,
            zones: [TestData.zone(seats: [TestData.seat(checkIns: [TestData.checkIn()]), TestData.seat()])]
        )
        repository.levelsResult = [level]
        let readAt = TestData.now.addingTimeInterval(5 * 60)

        _ = try await useCase.execute(building: building, now: readAt)

        #expect(snapshot.writtenLevels.count == 1)
        #expect(snapshot.writtenLevels.first?.buildingName == "Building 1")
        #expect(snapshot.writtenLevels.first?.readAt == readAt)
        #expect(
            snapshot.writtenLevels.first?.levels
                == [AvailabilitySnapshot.LevelCount(id: level.id, number: 5, free: 1, total: 2)]
        )
        #expect(widget.reloadCount == 1)
    }

    @Test func aFailedReadLeavesTheSnapshotUntouched() async throws {
        repository.readError = URLError(.notConnectedToInternet)

        await #expect(throws: URLError.self) {
            try await useCase.execute(building: TestData.building(), now: TestData.now)
        }
        #expect(snapshot.writtenLevels.isEmpty)
        #expect(widget.reloadCount == 0)
    }
}
