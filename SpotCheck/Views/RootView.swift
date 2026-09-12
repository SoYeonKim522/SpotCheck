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

    var body: some View {
        Text("SpotCheck")
            .task {
                do {
                    try SeedData.loadIfEmpty(into: context, now: Date())
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
