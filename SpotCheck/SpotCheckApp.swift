//
//  SpotCheckApp.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 29/9/2026.
//

import SwiftUI

@main
struct SpotCheckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    #if DEBUG
    init() {
        let divisor = UserDefaults.standard.double(forKey: "holdTimeDivisor")
        AppSettingsStore().debugTimeDivisor = divisor > 0 ? divisor : nil
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
