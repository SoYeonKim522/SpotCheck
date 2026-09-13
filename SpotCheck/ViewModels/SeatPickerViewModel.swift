//
//  SeatPickerViewModel.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 13/9/2026.
//

import Foundation
import Observation

@Observable
final class SeatPickerViewModel {
    let level: StudyLevel

    private(set) var selectedSeat: StudySeat?
    private(set) var checkInError: CheckIntoSeatError?
    private var now: Date

    private let occupant: OccupantIdentifier
    private let viewLevelAvailability = ViewLevelAvailabilityUseCase()
    private let checkIntoSeat: CheckIntoSeatUseCase
    private let onCheckIn: () -> Void

    init(
        level: StudyLevel,
        repository: StudySpaceRepository,
        occupant: OccupantIdentifier,
        now: Date,
        onCheckIn: @escaping () -> Void
    ) {
        self.level = level
        self.occupant = occupant
        self.checkIntoSeat = CheckIntoSeatUseCase(repository: repository)
        self.now = now
        self.onCheckIn = onCheckIn
    }

    var availability: LevelAvailability {
        viewLevelAvailability.execute(level: level, now: now)
    }

    var zones: [StudyZone] {
        level.zones
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func seats(in zone: StudyZone) -> [StudySeat] {
        zone.seats
            .sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }
    }

    func isFree(_ seat: StudySeat) -> Bool {
        seat.activeCheckIn(at: now) == nil
    }

    func isHeldByMe(_ seat: StudySeat) -> Bool {
        seat.activeCheckIn(at: now)?.checkedInBy == occupant
    }

    func select(_ seat: StudySeat) {
        guard isFree(seat) else { return }
        checkInError = nil
        selectedSeat = seat
    }

    func clearCheckInError() {
        checkInError = nil
    }

    func deselect() {
        checkInError = nil
        selectedSeat = nil
    }

    func checkIn(to seat: StudySeat, now: Date) {
        do {
            _ = try checkIntoSeat.execute(seat: seat, occupant: occupant, now: now)
            checkInError = nil
            refresh(now: now)
            onCheckIn()
        } catch let error as CheckIntoSeatError {
            checkInError = error
        } catch {
            assertionFailure("A check-in could not be saved: \(error)")
        }
    }

    func refresh(now: Date) {
        self.now = now
        if let selectedSeat, !isFree(selectedSeat) {
            self.selectedSeat = nil
        }
    }
}
