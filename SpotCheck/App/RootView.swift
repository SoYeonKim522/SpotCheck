import SwiftUI

struct RootView: View {
    @State private var session: AuthSession
    @State private var levelList: LevelListViewModel
    @State private var hasRestored = false

    private let repository: SupabaseStudySpaceRepository
    private let checkIntoSeat: CheckIntoSeatUseCase

    init() {
        let repository = SupabaseStudySpaceRepository()
        self.repository = repository
        let widget = WidgetCenterRefresher()
        let snapshot = AvailabilitySnapshotStore()
        checkIntoSeat = CheckIntoSeatUseCase(
            repository: repository,
            reminders: NoOpReminderScheduler(),
            widget: widget,
            snapshot: snapshot
        )
        _session = State(initialValue: AuthSession(repository: SupabaseAuthenticationRepository()))
        _levelList = State(
            initialValue: LevelListViewModel(
                repository: repository,
                viewLevelAvailability: ViewLevelAvailabilityUseCase(
                    repository: repository,
                    widget: widget,
                    snapshot: snapshot
                ),
                settings: AppSettingsStore()
            )
        )
    }

    var body: some View {
        Group {
            if !hasRestored {
                ProgressView()
            } else if session.isSignedIn {
                TabView {
                    Tab("Find a seat", systemImage: "building.2") {
                        LevelListView { availability in
                            SeatPickerViewModel(
                                availability: availability,
                                repository: repository,
                                checkIntoSeat: checkIntoSeat,
                                session: session
                            )
                        }
                    }
                }
            } else {
                SignInView()
            }
        }
        .environment(session)
        .environment(levelList)
        .task {
            await session.restore()
            hasRestored = true
        }
    }
}
