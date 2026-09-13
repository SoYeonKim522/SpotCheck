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
    @State private var isSeeded = false

    private let occupant = DeviceOccupant.identifier()

    var body: some View {
        NavigationStack {
            if isSeeded {
                LevelListView(
                    repository: SwiftDataStudySpaceRepository(context: context),
                    occupant: occupant
                )
            }
        }
        .task {
            do {
                try SeedData.loadIfEmpty(into: context, now: Date())
                isSeeded = true
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
