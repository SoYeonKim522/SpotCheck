import Foundation
import Observation

/// Holds what the seat picker shows: one level's zones and seats, and the seat the student picked.
///
/// The picker opens on the seats the level list already read, then reads them again.
/// `readAt` is the moment of the latest read, and every seat is judged free or taken at that moment.
@MainActor
@Observable
final class SeatPickerViewModel {
    let level: StudyLevel

    private(set) var readAt: Date
    private(set) var couldNotReach = false
    private(set) var selectedSeat: StudySeat?

    private var readZones: [StudyZone]

    private let repository: any StudySpaceRepository
    private let session: AuthSession

    init(availability: LevelAvailability, repository: any StudySpaceRepository, session: AuthSession) {
        self.level = availability.level
        self.readAt = availability.lastUpdatedAt
        self.readZones = availability.level.zones
        self.repository = repository
        self.session = session
    }

    var zones: [StudyZone] {
        readZones.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var freeCount: Int {
        readZones.flatMap(\.seats).filter(isFree).count
    }

    var totalCount: Int {
        readZones.flatMap(\.seats).count
    }

    func seats(in zone: StudyZone) -> [StudySeat] {
        zone.seats.sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }
    }

    func isFree(_ seat: StudySeat) -> Bool {
        seat.activeCheckIn(at: readAt) == nil
    }

    func isHeldByMe(_ seat: StudySeat) -> Bool {
        seat.activeCheckIn(at: readAt)?.checkedInBy == session.occupant
    }

    func select(_ seat: StudySeat) {
        guard isFree(seat) else { return }
        selectedSeat = seat
    }

    func deselect() {
        selectedSeat = nil
    }

    func refresh(now: Date) async {
        do {
            readZones = try await repository.zones(onLevel: level.id, at: now)
            readAt = now
            couldNotReach = false
            if let selectedSeat, !isFree(selectedSeat) {
                self.selectedSeat = nil
            }
        } catch {
            guard !Task.isCancelled else { return }
            couldNotReach = true
        }
    }
}
