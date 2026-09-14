//
//  SpotCheckTests.swift
//  SpotCheckTests
//
//  Created by MACBOOK_PRO on 7/9/2026.
//

import Foundation
import SwiftData
import Testing
@testable import SpotCheck

@MainActor
struct SpotCheckTests {
    private let context: ModelContext
    private let repository: SwiftDataStudySpaceRepository
    private let now = Date(timeIntervalSince1970: 1_757_000_000)
    private let me = OccupantIdentifier(value: "occupant-me")
    private let someoneElse = OccupantIdentifier(value: "occupant-else")

    init() throws {
        let container = try ModelContainer(
            for: CampusBuilding.self, StudyLevel.self, StudyZone.self, StudySeat.self, SeatCheckIn.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        repository = SwiftDataStudySpaceRepository(context: context)
    }

    @Test func checkingIntoAFreeSeatHoldsItForTheHoldDuration() throws {
        let seat = seat(0, on: level(5))

        let checkIn = try checkIn(me, into: seat, at: now)

        #expect(checkIn.checkedInBy == me)
        #expect(checkIn.checkedInAt == now)
        #expect(checkIn.expiresAt == now.addingTimeInterval(SeatHoldPolicy.duration))
        #expect(seat.activeCheckIn(at: now) === checkIn)
    }

    @Test func checkingIntoATakenSeatIsRejected() throws {
        let seat = seat(0, on: level(5))
        try checkIn(someoneElse, into: seat, at: now)

        let error = #expect(throws: CheckIntoSeatError.self) {
            try checkIn(me, into: seat, at: now.addingTimeInterval(60))
        }

        guard case .seatIsTaken? = error else {
            Issue.record("Expected seatIsTaken, got \(String(describing: error))")
            return
        }
    }

    @Test func anOccupantCannotHoldTwoSeatsAtOnce() throws {
        let level = level(5)
        let firstSeat = seat(0, on: level)
        try checkIn(me, into: firstSeat, at: now)

        let error = #expect(throws: CheckIntoSeatError.self) {
            try checkIn(me, into: seat(1, on: level), at: now.addingTimeInterval(60))
        }

        guard case .occupantAlreadyHoldsASeat(let heldSeat)? = error else {
            Issue.record("Expected occupantAlreadyHoldsASeat, got \(String(describing: error))")
            return
        }
        #expect(heldSeat === firstSeat)
    }

    @Test func aSeatCanBeClaimedAgainOnceTheEarlierHoldHasExpired() throws {
        let seat = seat(0, on: level(5))
        try checkIn(someoneElse, into: seat, at: now)

        let afterExpiry = now.addingTimeInterval(SeatHoldPolicy.duration)
        let checkIn = try checkIn(me, into: seat, at: afterExpiry)

        #expect(seat.activeCheckIn(at: afterExpiry) === checkIn)
    }

    @Test func releasingASeatMakesItFreeForSomeoneElse() throws {
        let seat = seat(0, on: level(5))
        let checkIn = try checkIn(me, into: seat, at: now)

        let releasedAt = now.addingTimeInterval(10 * 60)
        try ReleaseSeatUseCase(repository: repository).execute(checkIn: checkIn, occupant: me, now: releasedAt)

        #expect(checkIn.releasedAt == releasedAt)
        #expect(seat.activeCheckIn(at: releasedAt) == nil)
    }

    @Test func anotherOccupantCannotReleaseSomeoneElsesSeat() throws {
        let checkIn = try checkIn(me, into: seat(0, on: level(5)), at: now)

        #expect(throws: ReleaseSeatError.checkInBelongsToAnotherOccupant) {
            try ReleaseSeatUseCase(repository: repository).execute(checkIn: checkIn, occupant: someoneElse, now: now)
        }
        #expect(checkIn.releasedAt == nil)
    }

    @Test func aSeatCannotBeReleasedTwice() throws {
        let checkIn = try checkIn(me, into: seat(0, on: level(5)), at: now)
        let releaseSeat = ReleaseSeatUseCase(repository: repository)
        try releaseSeat.execute(checkIn: checkIn, occupant: me, now: now)

        #expect(throws: ReleaseSeatError.seatWasAlreadyReleased) {
            try releaseSeat.execute(checkIn: checkIn, occupant: me, now: now.addingTimeInterval(60))
        }
    }

    @Test func anExpiredHoldCannotBeReleased() throws {
        let checkIn = try checkIn(me, into: seat(0, on: level(5)), at: now)

        #expect(throws: ReleaseSeatError.holdHasAlreadyExpired) {
            try ReleaseSeatUseCase(repository: repository)
                .execute(checkIn: checkIn, occupant: me, now: now.addingTimeInterval(SeatHoldPolicy.duration))
        }
    }

    @Test func extendingAHoldPushesTheExpiryOutByOneMoreHoldDuration() throws {
        let checkIn = try checkIn(me, into: seat(0, on: level(5)), at: now)

        try ExtendHoldUseCase(repository: repository)
            .execute(checkIn: checkIn, occupant: me, now: now.addingTimeInterval(30 * 60))

        #expect(checkIn.expiresAt == now.addingTimeInterval(2 * SeatHoldPolicy.duration))
    }

    @Test func aHoldCanBeExtendedUpToTheMaximumHoldDuration() throws {
        let checkIn = try checkIn(me, into: seat(0, on: level(5)), at: now)
        let extendHold = ExtendHoldUseCase(repository: repository)

        try extendHold.execute(checkIn: checkIn, occupant: me, now: now.addingTimeInterval(30 * 60))
        try extendHold.execute(checkIn: checkIn, occupant: me, now: now.addingTimeInterval(90 * 60))

        #expect(checkIn.expiresAt == SeatHoldPolicy.latestExpiry(for: now))
    }

    @Test func aHoldCannotBeExtendedPastTheMaximumHoldDuration() throws {
        let checkIn = try checkIn(me, into: seat(0, on: level(5)), at: now)
        let extendHold = ExtendHoldUseCase(repository: repository)
        try extendHold.execute(checkIn: checkIn, occupant: me, now: now.addingTimeInterval(30 * 60))
        try extendHold.execute(checkIn: checkIn, occupant: me, now: now.addingTimeInterval(90 * 60))

        #expect(throws: ExtendHoldError.holdIsAtItsMaximum) {
            try extendHold.execute(checkIn: checkIn, occupant: me, now: now.addingTimeInterval(150 * 60))
        }
        #expect(checkIn.expiresAt == SeatHoldPolicy.latestExpiry(for: now))
    }

    @Test func anotherOccupantCannotExtendSomeoneElsesHold() throws {
        let checkIn = try checkIn(me, into: seat(0, on: level(5)), at: now)

        #expect(throws: ExtendHoldError.checkInBelongsToAnotherOccupant) {
            try ExtendHoldUseCase(repository: repository)
                .execute(checkIn: checkIn, occupant: someoneElse, now: now)
        }
    }

    @Test func anExpiredHoldCannotBeExtended() throws {
        let checkIn = try checkIn(me, into: seat(0, on: level(5)), at: now)

        #expect(throws: ExtendHoldError.holdHasAlreadyExpired) {
            try ExtendHoldUseCase(repository: repository)
                .execute(checkIn: checkIn, occupant: me, now: now.addingTimeInterval(SeatHoldPolicy.duration))
        }
    }

    @Test func aReleasedSeatCannotHaveItsHoldExtended() throws {
        let checkIn = try checkIn(me, into: seat(0, on: level(5)), at: now)
        try ReleaseSeatUseCase(repository: repository).execute(checkIn: checkIn, occupant: me, now: now)

        #expect(throws: ExtendHoldError.seatWasAlreadyReleased) {
            try ExtendHoldUseCase(repository: repository)
                .execute(checkIn: checkIn, occupant: me, now: now.addingTimeInterval(60))
        }
    }

    @Test func aLevelCountsOnlySeatsWithoutAnActiveCheckIn() throws {
        let level = level(5, seats: 4)
        try checkIn(someoneElse, into: seat(0, on: level), at: now)

        let availability = ViewLevelAvailabilityUseCase().execute(level: level, now: now)

        #expect(availability.free == 3)
        #expect(availability.total == 4)
        #expect(availability.lastUpdatedAt == now)
    }

    @Test func anExpiredCheckInStopsCountingTowardsOccupancy() throws {
        let level = level(5, seats: 4)
        try checkIn(someoneElse, into: seat(0, on: level), at: now)

        let afterExpiry = now.addingTimeInterval(SeatHoldPolicy.duration)

        #expect(ViewLevelAvailabilityUseCase().execute(level: level, now: afterExpiry).free == 4)
    }

    @Test func levelsAreListedInFloorOrder() {
        let building = insertBuilding(levels: [(9, 2), (4, 2), (5, 2)])

        let availabilities = ViewLevelAvailabilityUseCase().execute(building: building, now: now)

        #expect(availabilities.map(\.level.number) == [4, 5, 9])
    }

    @Test func aLevelsFullnessFollowsHowManySeatsAreLeft() {
        #expect(LevelFullness(free: 5, total: 10) == .plenty)
        #expect(LevelFullness(free: 3, total: 10) == .fillingUp)
        #expect(LevelFullness(free: 1, total: 10) == .nearlyFull)
        #expect(LevelFullness(free: 0, total: 0) == .nearlyFull)
    }

    @Test func theStoreListsBuildingsInTheOrderStudentsReadThem() throws {
        insertBuilding(named: "Building 11")
        insertBuilding(named: "Building 2")
        insertBuilding(named: "Building 1")

        #expect(try repository.buildings().map(\.name) == ["Building 1", "Building 2", "Building 11"])
    }

    @Test func theStoreFindsAnOccupantsCurrentSeatButNotAnExpiredOne() throws {
        let checkIn = try checkIn(me, into: seat(0, on: level(5)), at: now)

        #expect(try repository.activeCheckIn(for: me, at: now) === checkIn)
        #expect(try repository.activeCheckIn(for: someoneElse, at: now) == nil)
        #expect(try repository.activeCheckIn(for: me, at: now.addingTimeInterval(SeatHoldPolicy.duration)) == nil)
    }

    @Test func takingASeatSomeoneElseJustClaimedTellsTheStudentWhy() throws {
        let level = level(5)
        let seat = seat(0, on: level)
        let viewModel = SeatPickerViewModel(level: level, repository: repository, occupant: me, now: now, onCheckIn: {})
        viewModel.select(seat)

        try checkIn(someoneElse, into: seat, at: now)
        viewModel.checkIn(to: seat, now: now)

        guard case .seatIsTaken? = viewModel.checkInError else {
            Issue.record("Expected seatIsTaken, got \(String(describing: viewModel.checkInError))")
            return
        }
        viewModel.refresh(now: now)
        #expect(viewModel.selectedSeat == nil)
    }

    @Test func releasingAHoldThatHasAlreadyEndedTellsTheStudentWhy() throws {
        try checkIn(me, into: seat(0, on: level(5)), at: now)
        let viewModel = MyCheckInViewModel(repository: repository, occupant: me)
        viewModel.refresh(now: now)

        viewModel.release(now: now.addingTimeInterval(SeatHoldPolicy.duration))

        #expect(viewModel.actionError as? ReleaseSeatError == .holdHasAlreadyExpired)
        #expect(viewModel.checkIn == nil)
    }

    @discardableResult
    private func insertBuilding(
        named name: String = "Building 2",
        levels: [(number: Int, seats: Int)] = [(5, 4)]
    ) -> CampusBuilding {
        let building = CampusBuilding(name: name, address: "61 Broadway, Ultimo")
        building.levels = levels.map { number, seatCount in
            let level = StudyLevel(number: number)
            let zone = StudyZone(name: "Reading Room", noiseLevel: .silent)
            zone.seats = (0..<seatCount).map { StudySeat(label: "\(number)R\($0 + 1)", hasPowerOutlet: true) }
            level.zones = [zone]
            return level
        }
        context.insert(building)
        return building
    }

    private func level(_ number: Int, seats seatCount: Int = 4) -> StudyLevel {
        insertBuilding(levels: [(number, seatCount)]).levels[0]
    }

    private func seat(_ index: Int, on level: StudyLevel) -> StudySeat {
        level.zones
            .flatMap(\.seats)
            .sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }[index]
    }

    @discardableResult
    private func checkIn(_ occupant: OccupantIdentifier, into seat: StudySeat, at moment: Date) throws -> SeatCheckIn {
        try CheckIntoSeatUseCase(repository: repository).execute(seat: seat, occupant: occupant, now: moment)
    }
}
