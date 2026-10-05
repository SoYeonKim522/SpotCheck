import Foundation
import Observation

/// Holds the seat the signed-in student is holding, and the actions on it.
///
/// The hold bar and the My check-in screen both read this one object, so they always agree.
/// A failed release or extension becomes a `Notice`, which `RootView` shows in a single alert.
@MainActor
@Observable
final class MyCheckInViewModel {
    struct Notice {
        let title: String
        let message: String

        init(_ error: some LocalizedError) {
            title = error.errorDescription ?? ""
            message = error.recoverySuggestion ?? ""
        }

        init() {
            title = "Couldn't reach SpotCheck"
            message = "Check your connection, then try again."
        }
    }

    private(set) var state = LoadState.loading
    private(set) var hold: SeatHold?
    private(set) var notice: Notice?
    private(set) var isWorking = false
    var isConfirmingRelease = false

    private let repository: any StudySpaceRepository
    private let releaseSeat: ReleaseSeatUseCase
    private let extendHold: ExtendHoldUseCase
    private let session: AuthSession

    init(
        repository: any StudySpaceRepository,
        releaseSeat: ReleaseSeatUseCase,
        extendHold: ExtendHoldUseCase,
        session: AuthSession
    ) {
        self.repository = repository
        self.releaseSeat = releaseSeat
        self.extendHold = extendHold
        self.session = session
    }

    func refresh(now: Date) async {
        guard let occupant = session.occupant else { return }
        if state == .couldNotReach {
            state = .loading
        }

        do {
            hold = try await repository.activeHold(for: occupant, at: now)
            state = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            if hold == nil {
                state = .couldNotReach
            }
        }
    }

    func waitForExpiry() async {
        guard let expiresAt = hold?.checkIn.expiresAt else { return }
        try? await Task.sleep(for: .seconds(max(0, expiresAt.timeIntervalSinceNow)))
        guard !Task.isCancelled else { return }
        await refresh(now: .now)
    }

    func didCheckIn(_ hold: SeatHold) {
        self.hold = hold
        state = .loaded
    }

    func reset() {
        hold = nil
        notice = nil
        state = .loading
    }

    func askToRelease() {
        guard hold != nil else { return }
        isConfirmingRelease = true
    }

    func clearNotice() {
        notice = nil
    }

    func extend(now: Date) async {
        guard let hold, let occupant = session.occupant else { return }

        isWorking = true
        notice = nil
        defer { isWorking = false }

        do {
            self.hold = try await extendHold.execute(hold: hold, occupant: occupant, now: now)
        } catch {
            guard !Task.isCancelled else { return }
            notice = makeNotice(for: error)
            await refresh(now: now)
        }
    }

    func release(now: Date) async {
        guard let hold, let occupant = session.occupant else { return }

        isWorking = true
        notice = nil
        defer { isWorking = false }

        do {
            try await releaseSeat.execute(checkIn: hold.checkIn, occupant: occupant, now: now)
            self.hold = nil
        } catch {
            guard !Task.isCancelled else { return }
            notice = makeNotice(for: error)
            await refresh(now: now)
        }
    }

    private func makeNotice(for error: any Error) -> Notice {
        switch error {
        case let error as ExtendHoldError: Notice(error)
        case let error as ReleaseSeatError: Notice(error)
        default: Notice()
        }
    }
}
