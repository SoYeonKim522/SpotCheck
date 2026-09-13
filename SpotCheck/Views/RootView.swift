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
        .task {
            do {
                try SeedData.loadIfEmpty(into: context, now: .now)
                let model = MyCheckInViewModel(
                    repository: SwiftDataStudySpaceRepository(context: context),
                    occupant: occupant
                )
                model.refresh(now: .now)
                hold = model
            } catch {
                assertionFailure("Seed data failed to load: \(error)")
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: CampusBuilding.self, inMemory: true)
}
