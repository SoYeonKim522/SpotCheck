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
    private var now: Date

    private let occupant: OccupantIdentifier
    private let viewLevelAvailability = ViewLevelAvailabilityUseCase()
    private let checkIntoSeat: CheckIntoSeatUseCase

    init(level: StudyLevel, repository: StudySpaceRepository, occupant: OccupantIdentifier, now: Date) {
        self.level = level
        self.occupant = occupant
        self.checkIntoSeat = CheckIntoSeatUseCase(repository: repository)
        self.now = now
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

    func select(_ seat: StudySeat) {
        guard isFree(seat) else { return }
        selectedSeat = seat
    }

    func deselect() {
        selectedSeat = nil
    }

    func refresh(now: Date) {
        self.now = now
        if let selectedSeat, !isFree(selectedSeat) {
            self.selectedSeat = nil
        }
    }
}
