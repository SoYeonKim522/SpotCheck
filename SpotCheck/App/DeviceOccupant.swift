//
//  DeviceOccupant.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 10/9/2026.
//

import Foundation

enum DeviceOccupant {
    private static let key = "spotcheck.occupantIdentifier"

    static func identifier(in defaults: UserDefaults = .standard) -> OccupantIdentifier {
        if let stored = defaults.string(forKey: key) {
            return OccupantIdentifier(value: stored)
        }
        let generated = UUID().uuidString
        defaults.set(generated, forKey: key)
        return OccupantIdentifier(value: generated)
    }
}
