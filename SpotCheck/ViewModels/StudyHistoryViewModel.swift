import Foundation
import Observation

/// Holds the signed-in student's finished check-ins and the study time for the current week.
///
/// History is read for one person, so check-ins made by other people, including the seeded
/// demo students, never appear. A check-in still in progress is not listed.
@MainActor
@Observable
final class StudyHistoryViewModel {
    private(set) var state = LoadState.loading
    private(set) var holds: [SeatHold] = []
    private(set) var studyTimeThisWeek: TimeInterval = 0

    private let repository: any StudySpaceRepository
    private let session: AuthSession

    init(repository: any StudySpaceRepository, session: AuthSession) {
        self.repository = repository
        self.session = session
    }

    func refresh(now: Date, calendar: Calendar = .current) async {
        guard let occupant = session.occupant else { return }
        if state == .couldNotReach {
            state = .loading
        }

        do {
            holds = try await repository.history(for: occupant, at: now)
            studyTimeThisWeek = Self.studyTime(of: holds, inWeekOf: now, calendar: calendar)
            state = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            if holds.isEmpty {
                state = .couldNotReach
            }
        }
    }

    func reset() {
        holds = []
        studyTimeThisWeek = 0
        state = .loading
    }

    /// The time at the seat for check-ins made in the week that contains `now`.
    /// The calendar decides which weekday the week starts on.
    static func studyTime(of holds: [SeatHold], inWeekOf now: Date, calendar: Calendar) -> TimeInterval {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return holds
            .map(\.checkIn)
            .filter { week.contains($0.checkedInAt) }
            .reduce(0) { $0 + $1.timeAtSeat }
    }
}
