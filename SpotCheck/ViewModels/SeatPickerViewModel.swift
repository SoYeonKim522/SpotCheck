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
    private(set) var checkInMessage: String?
    private(set) var isCheckingIn = false

    private var readZones: [StudyZone]

    private let repository: any StudySpaceRepository
    private let checkIntoSeat: CheckIntoSeatUseCase
    private let session: AuthSession

    init(
        availability: LevelAvailability,
        repository: any StudySpaceRepository,
        checkIntoSeat: CheckIntoSeatUseCase,
        session: AuthSession
    ) {
        self.level = availability.level
        self.readAt = availability.lastUpdatedAt
        self.readZones = availability.level.zones
        self.repository = repository
        self.checkIntoSeat = checkIntoSeat
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

    func zoneName(of seat: StudySeat) -> String {
        readZones.first { $0.id == seat.zoneID }?.name ?? ""
    }

    func select(_ seat: StudySeat) {
        guard isFree(seat) else { return }
        checkInMessage = nil
        selectedSeat = seat
    }

    func deselect() {
        checkInMessage = nil
        selectedSeat = nil
    }

    func checkIn(to seat: StudySeat, now: Date) async {
        guard let occupant = session.occupant else {
            assertionFailure("A check-in was started without a signed-in occupant.")
            return
        }

        isCheckingIn = true
        checkInMessage = nil
        defer { isCheckingIn = false }

        do {
            _ = try await checkIntoSeat.execute(seat: seat, occupant: occupant, now: now)
            selectedSeat = nil
            await refresh(now: now)
        } catch let error as CheckIntoSeatError {
            checkInMessage = [error.errorDescription, error.recoverySuggestion]
                .compactMap { $0 }
                .joined(separator: " ")
            await refresh(now: now)
        } catch {
            guard !Task.isCancelled else { return }
            checkInMessage = "Couldn't reach SpotCheck. Check your connection, then try again."
        }
    }

    func refresh(now: Date) async {
        do {
            readZones = try await repository.zones(onLevel: level.id, at: now)
            readAt = now
            couldNotReach = false
        } catch {
            guard !Task.isCancelled else { return }
            couldNotReach = true
        }
    }
}
