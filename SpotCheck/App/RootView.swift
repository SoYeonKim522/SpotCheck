import SwiftUI

struct RootView: View {
    @State private var session: AuthSession
    @State private var levelList: LevelListViewModel
    @State private var hasRestored = false

    init() {
        let repository = SupabaseStudySpaceRepository()
        _session = State(initialValue: AuthSession(repository: SupabaseAuthenticationRepository()))
        _levelList = State(
            initialValue: LevelListViewModel(
                repository: repository,
                viewLevelAvailability: ViewLevelAvailabilityUseCase(
                    repository: repository,
                    widget: WidgetCenterRefresher(),
                    snapshot: AvailabilitySnapshotStore()
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
                        LevelListView()
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
