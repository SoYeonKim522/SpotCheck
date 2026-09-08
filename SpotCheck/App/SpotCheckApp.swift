//
//  SpotCheckApp.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 7/9/2026.
//

import SwiftUI
import SwiftData

@main
struct SpotCheckApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [CampusBuilding.self, StudyLevel.self, StudyZone.self, StudySeat.self, SeatCheckIn.self])
    }
}
