//
//  SpotCheckApp.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 29/9/2026.
//

import SwiftUI
import CoreData

@main
struct SpotCheckApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
