import Foundation
import Testing
@testable import SpotCheck

@MainActor
struct StudyHistoryTests {
    let repository = MockStudySpaceRepository()

    @Test func timeAtTheSeatEndsWhenTheSeatWasReleased() {
        let checkIn = TestData.checkIn(releasedAt: TestData.now.addingTimeInterval(20 * 60))

        #expect(checkIn.timeAtSeat == 20 * 60)
    }

    @Test func aCheckInThatWasNeverReleasedCountsUntilItExpired() {
        let checkIn = TestData.checkIn()

        #expect(checkIn.timeAtSeat == SeatHoldPolicy.duration)
    }

    @Test func historyListsOnlyFinishedCheckInsOfTheSamePerson() async throws {
        let occupant = TestData.occupant()
        let finished = TestData.hold(of: TestData.checkIn(by: occupant, at: TestData.now.addingTimeInterval(-2 * 3600)))
        let inProgress = TestData.hold(of: TestData.checkIn(by: occupant, at: TestData.now.addingTimeInterval(-600)))
        let someoneElses = TestData.hold(of: TestData.checkIn(at: TestData.now.addingTimeInterval(-2 * 3600)))
        repository.seatHolds = [finished, inProgress, someoneElses]

        let history = try await repository.history(for: occupant, at: TestData.now)

        #expect(history == [finished])
    }

    @Test func studyTimeThisWeekLeavesOutCheckInsFromEarlierWeeks() throws {
        let calendar = calendar(firstWeekday: 2)
        let wednesday = try date(year: 2026, month: 10, day: 7, calendar: calendar)
        let thisWeek = TestData.hold(of: TestData.checkIn(at: wednesday.addingTimeInterval(-3600)))
        let lastWeek = TestData.hold(of: TestData.checkIn(at: wednesday.addingTimeInterval(-8 * 24 * 3600)))

        let total = StudyHistoryViewModel.studyTime(of: [thisWeek, lastWeek], inWeekOf: wednesday, calendar: calendar)

        #expect(total == SeatHoldPolicy.duration)
    }

    @Test func theWeekStartsOnTheCalendarsFirstWeekday() throws {
        let sunday = try date(year: 2026, month: 10, day: 4, hour: 10, calendar: calendar(firstWeekday: 1))
        let tuesday = try date(year: 2026, month: 10, day: 6, calendar: calendar(firstWeekday: 1))
        let onSunday = TestData.hold(of: TestData.checkIn(at: sunday))

        let sundayStart = StudyHistoryViewModel.studyTime(of: [onSunday], inWeekOf: tuesday, calendar: calendar(firstWeekday: 1))
        let mondayStart = StudyHistoryViewModel.studyTime(of: [onSunday], inWeekOf: tuesday, calendar: calendar(firstWeekday: 2))

        #expect(sundayStart == SeatHoldPolicy.duration)
        #expect(mondayStart == 0)
    }

    private func calendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 12, calendar: Calendar) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)))
    }
}
