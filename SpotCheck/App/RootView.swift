import SwiftUI

struct RootView: View {
    private enum AppTab {
        case findASeat
        case myCheckIn
    }

    @Environment(\.scenePhase) private var scenePhase

    @State private var session: AuthSession
    @State private var levelList: LevelListViewModel
    @State private var myCheckIn: MyCheckInViewModel
    @State private var selectedTab = AppTab.findASeat
    @State private var hasRestored = false

    private let repository: SupabaseStudySpaceRepository
    private let checkIntoSeat: CheckIntoSeatUseCase

    init() {
        let repository = SupabaseStudySpaceRepository()
        let widget = WidgetCenterRefresher()
        let snapshot = AvailabilitySnapshotStore()
        let reminders = NoOpReminderScheduler()
        let session = AuthSession(repository: SupabaseAuthenticationRepository())

        self.repository = repository
        checkIntoSeat = CheckIntoSeatUseCase(
            repository: repository,
            reminders: reminders,
            widget: widget,
            snapshot: snapshot
        )
        _session = State(initialValue: session)
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
        _myCheckIn = State(
            initialValue: MyCheckInViewModel(
                repository: repository,
                releaseSeat: ReleaseSeatUseCase(
                    repository: repository,
                    reminders: reminders,
                    widget: widget,
                    snapshot: snapshot
                ),
                extendHold: ExtendHoldUseCase(
                    repository: repository,
                    reminders: reminders,
                    widget: widget,
                    snapshot: snapshot
                ),
                session: session
            )
        )
    }

    var body: some View {
        Group {
            if !hasRestored {
                ProgressView()
            } else if session.isSignedIn {
                signedIn
            } else {
                SignInView()
            }
        }
        .environment(session)
        .environment(levelList)
        .environment(myCheckIn)
        .task {
            await session.restore()
            hasRestored = true
        }
        .onChange(of: session.isSignedIn) {
            if !session.isSignedIn {
                myCheckIn.reset()
                selectedTab = .findASeat
            }
        }
    }

    private var signedIn: some View {
        TabView(selection: $selectedTab) {
            Tab("Find a seat", systemImage: "building.2", value: AppTab.findASeat) {
                LevelListView { availability in
                    SeatPickerViewModel(
                        availability: availability,
                        repository: repository,
                        checkIntoSeat: checkIntoSeat,
                        session: session,
                        onCheckIn: { hold in
                            myCheckIn.didCheckIn(hold)
                            selectedTab = .myCheckIn
                        }
                    )
                }
            }
            Tab("My check-in", systemImage: "clock", value: AppTab.myCheckIn) {
                MyCheckInView()
            }
        }
        .tabViewBottomAccessory(isEnabled: myCheckIn.hold != nil && selectedTab != .myCheckIn) {
            if let hold = myCheckIn.hold {
                CheckInBar(
                    hold: hold,
                    open: { selectedTab = .myCheckIn },
                    release: { myCheckIn.askToRelease() }
                )
            }
        }
        .task(id: session.occupant) { await myCheckIn.refresh(now: .now) }
        .task(id: myCheckIn.hold?.checkIn.expiresAt) { await myCheckIn.waitForExpiry() }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task { await myCheckIn.refresh(now: .now) }
            }
        }
        .alert(
            myCheckIn.notice?.title ?? "",
            isPresented: Binding(
                get: { myCheckIn.notice != nil },
                set: { if !$0 { myCheckIn.clearNotice() } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(myCheckIn.notice?.message ?? "") }
        )
        .alert(
            "Release \(myCheckIn.hold?.seatLabel ?? "seat")?",
            isPresented: $myCheckIn.isConfirmingRelease
        ) {
            Button("Release seat", role: .destructive) {
                Task { await myCheckIn.release(now: .now) }
            }
            Button("Keep seat", role: .cancel) {}
        } message: {
            Text("Someone else can claim it straight away.")
        }
    }
}
