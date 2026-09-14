//
//  MyCheckInViewModel.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 13/9/2026.
//

import Foundation
import Observation

@Observable
final class MyCheckInViewModel {
    private(set) var checkIn: SeatCheckIn?
    private(set) var actionError: (any LocalizedError)?

    private let occupant: OccupantIdentifier
    private let repository: StudySpaceRepository
    private let releaseSeat: ReleaseSeatUseCase
    private let extendHold: ExtendHoldUseCase

    init(repository: StudySpaceRepository, occupant: OccupantIdentifier) {
        self.repository = repository
        self.occupant = occupant
        self.releaseSeat = ReleaseSeatUseCase(repository: repository)
        self.extendHold = ExtendHoldUseCase(repository: repository)
    }

    func clearActionError() {
        actionError = nil
    }

    func refresh(now: Date) {
        do {
            checkIn = try repository.activeCheckIn(for: occupant, at: now)
        } catch {
            assertionFailure("The current check-in could not be loaded: \(error)")
            checkIn = nil
        }
    }

    func extend(now: Date) {
        guard let checkIn else { return }
        do {
            try extendHold.execute(checkIn: checkIn, occupant: occupant, now: now)
            actionError = nil
            refresh(now: now)
        } catch let error as ExtendHoldError {
            actionError = error
            refresh(now: now)
        } catch {
            assertionFailure("A hold could not be extended: \(error)")
        }
    }

    func release(now: Date) {
        guard let checkIn else { return }
        do {
            try releaseSeat.execute(checkIn: checkIn, occupant: occupant, now: now)
            actionError = nil
            refresh(now: now)
        } catch let error as ReleaseSeatError {
            actionError = error
            refresh(now: now)
        } catch {
            assertionFailure("A seat could not be released: \(error)")
        }
    }
}
