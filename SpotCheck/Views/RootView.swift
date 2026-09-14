//
//  RootView.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 7/9/2026.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var path = NavigationPath()
    @State private var hold: MyCheckInViewModel?
    @State private var isViewingCheckIn = false

    private let occupant = DeviceOccupant.identifier()

    var body: some View {
        NavigationStack(path: $path) {
            if let hold {
                LevelListView(
                    repository: SwiftDataStudySpaceRepository(context: context),
                    occupant: occupant,
                    onCheckIn: {
                        hold.refresh(now: .now)
                        if let checkIn = hold.checkIn { path.append(checkIn) }
                    }
                )
                .navigationDestination(for: SeatCheckIn.self) { _ in
                    MyCheckInView(viewModel: hold, isOnScreen: $isViewingCheckIn)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let hold, let checkIn = hold.checkIn, !isViewingCheckIn {
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    CheckInBar(
                        checkIn: checkIn,
                        now: .now,
                        open: { path.append(checkIn) },
                        release: { hold.release(now: .now) }
                    )
                }
            }
        }
        .alert(
            hold?.actionError?.errorDescription ?? "",
            isPresented: actionFailed,
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(hold?.actionError?.recoverySuggestion ?? "") }
        )
        .task {
            do {
                try SeedData.loadIfEmpty(into: context, now: .now)
            } catch {
                assertionFailure("Seed data failed to load: \(error)")
            }
            let model = MyCheckInViewModel(
                repository: SwiftDataStudySpaceRepository(context: context),
                occupant: occupant
            )
            model.refresh(now: .now)
            hold = model
        }
    }

    private var actionFailed: Binding<Bool> {
        Binding(
            get: { hold?.actionError != nil },
            set: { if !$0 { hold?.clearActionError() } }
        )
    }
}

#Preview {
    RootView()
        .modelContainer(for: CampusBuilding.self, inMemory: true)
}
